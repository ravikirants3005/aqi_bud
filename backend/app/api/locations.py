"""
Location management API routes
Saved locations for monitoring
"""

from fastapi import APIRouter, Depends
from typing import List, Dict, Any

from ..core.security import get_current_user
from ..core.database import get_db
from ..core.serializers import (
    normalize_saved_location_payload,
    serialize_saved_location,
)

router = APIRouter()

@router.post("/save")
async def save_location(location_data: Dict[str, Any], current_user: Dict = Depends(get_current_user)):
    """Save a location for user"""
    user_id = current_user["id"]
    db = get_db()
    # Add user_id to location data from authenticated token and normalize
    location_data["user_id"] = user_id
    normalized_location = normalize_saved_location_payload(location_data, user_id=user_id)
    saved_location = await db.create_saved_location(normalized_location)
    saved_location_row = saved_location[0] if isinstance(saved_location, list) and saved_location else saved_location
    return {"message": "Location saved successfully", "location": serialize_saved_location(saved_location_row)}

@router.get("/saved")
async def get_saved_locations(current_user: Dict = Depends(get_current_user)):
    """Get user's saved locations"""
    user_id = current_user["id"]
    db = get_db()
    locations = await db.get_saved_locations(user_id)
    return {"locations": [serialize_saved_location(location) for location in locations]}

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
