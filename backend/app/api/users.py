"""
User management API routes
Profile management and analytics
"""

from fastapi import APIRouter, Depends
from typing import Dict, Any

from ..core.security import get_current_user
from ..core.database import get_db
from ..services.supabase_service import SupabaseService
from ..core.serializers import serialize_user_profile

router = APIRouter()

supabase_service = SupabaseService()

@router.get("/profile")
async def get_user_profile(current_user: Dict = Depends(get_current_user)):
    """Get current user profile"""
    user_id = current_user["id"]
    db = get_db()
    profile = await db.get_user_profile(user_id)
    
    if not profile:
        # Create profile if it doesn't exist
        profile_data = {
            "id": user_id,
            "email": current_user.get("email"),
            "display_name": current_user.get("user_metadata", {}).get("display_name", "User"),
            "health_sensitivity": current_user.get("user_metadata", {}).get("health_sensitivity", "normal")
        }
        profile = await db.create_user_profile(profile_data)
    
    return serialize_user_profile(profile)

@router.put("/profile")
async def update_user_profile(profile_data: Dict[str, Any], current_user: Dict = Depends(get_current_user)):
    """Update user profile"""
    user_id = current_user["id"]
    db = get_db()
    
    # Add user_id from authenticated token
    profile_data = {**profile_data, "id": user_id}
    
    updated_profile = await db.update_user_profile(user_id, profile_data)
    return {"message": "Profile updated successfully", "profile": serialize_user_profile(updated_profile)}

@router.get("/analytics")
async def get_user_analytics(current_user: Dict = Depends(get_current_user)):
    """Get user analytics data"""
    user_id = current_user["id"]
    analytics = await supabase_service.get_user_analytics(user_id)
    return analytics
