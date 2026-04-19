"""
Location management API routes
Saved locations for monitoring
"""

from fastapi import APIRouter, Depends
from typing import List, Dict, Any

from ..core.security import get_current_user
from ..core.database import get_db

router = APIRouter()

@router.post("/save")
async def save_location(location_data: Dict[str, Any], current_user: Dict = Depends(get_current_user)):
    """Save a location for user"""
    user_id = current_user["id"]
    db = get_db()
    
    # Add user_id to location data from authenticated token
    location_data["user_id"] = user_id
    
    await db.create_saved_location(location_data)
    return {"message": "Location saved successfully"}

@router.get("/saved")
async def get_saved_locations(current_user: Dict = Depends(get_current_user)):
    """Get user's saved locations"""
    user_id = current_user["id"]
    db = get_db()
    locations = await db.get_saved_locations(user_id)
    return {"locations": locations}

@router.delete("/{location_id}")
async def delete_saved_location(location_id: str, current_user: Dict = Depends(get_current_user)):
    """Delete a saved location"""
    user_id = current_user["id"]
    db = get_db()
    
    # Verify location belongs to user
    user_locations = await db.get_saved_locations(user_id)
    location = next((loc for loc in user_locations if loc["id"] == location_id), None)
    
    if not location:
        raise Exception("Location not found")
    
    await db.delete_saved_location(location_id)
    return {"message": "Location deleted successfully"}
