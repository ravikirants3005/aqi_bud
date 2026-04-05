"""
Authentication API routes
Using Supabase for authentication - no manual auth needed
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from typing import Dict, Any

from ..core.security import get_current_user, extract_health_sensitivity, extract_display_name
from ..core.database import get_db
from ..models.user import UserProfile
from ..core.serializers import serialize_user_profile

router = APIRouter()

# Note: Authentication is handled by Supabase Flutter SDK
# These endpoints are no longer needed - remove manual auth

@router.get("/me")
async def get_current_user_info(current_user: Dict = Depends(get_current_user)):
    """Get current user profile (authenticated via Supabase)"""
    user_id = current_user["id"]
    db = get_db()
    
    # Get user profile from database
    profile = await db.get_user_profile(user_id)
    if not profile:
        return {"message": "User profile not found", "user_id": user_id}
    
    return {"profile": serialize_user_profile(profile)}

@router.post("/register")
async def register_user(current_user: Dict = Depends(get_current_user)):
    """Register user profile after authentication"""
    user_id = current_user["id"]
    db = get_db()
    
    # Check if profile already exists
    existing_profile = await db.get_user_profile(user_id)
    if existing_profile:
        return {"message": "User already registered", "user_id": user_id}
    
    # Create user profile
    profile_data = {
        "id": user_id,
        "email": current_user.get("email"),
        "phone": current_user.get("phone"),
        "display_name": extract_display_name(current_user),
        "health_sensitivity": extract_health_sensitivity(current_user)
    }
    
    await db.create_user_profile(profile_data)
    
    return {"message": "User registered successfully", "user_id": user_id}
