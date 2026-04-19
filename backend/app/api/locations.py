"""
Location management API routes
Saved locations for monitoring
"""

from fastapi import APIRouter, Depends, HTTPException
from typing import List, Dict, Any
import logging

from ..core.security import get_current_user
from ..core.database import get_db
from ..core.serializers import (
    normalize_saved_location_payload,
    serialize_saved_location,
)

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/save")
async def save_location(location_data: Dict[str, Any], current_user: Dict = Depends(get_current_user)):
    """Save a location for user"""
    try:
        user_id = current_user["id"]
        db = get_db()
        
        # Ensure user profile exists in database (auto-create if not)
        profile = await db.get_user_profile(user_id)
        if not profile:
            logger.info(f"Creating user profile for {user_id}")
            profile_data = {
                "id": user_id,
                "email": current_user.get("email"),
                "display_name": current_user.get("user_metadata", {}).get("display_name", "User"),
                "health_sensitivity": current_user.get("user_metadata", {}).get("health_sensitivity", "normal")
            }
            await db.create_user_profile(profile_data)
        
        # Add user_id to location data from authenticated token and normalize
        location_data["user_id"] = user_id
        normalized_location = normalize_saved_location_payload(location_data, user_id=user_id)
        
        logger.info(f"Saving location for user {user_id}: {normalized_location.get('name')}")
        
        saved_location = await db.create_saved_location(normalized_location)
        
        if not saved_location:
            logger.error("Database returned empty response")
            raise HTTPException(status_code=500, detail="Failed to save location to database")
        
        saved_location_row = saved_location[0] if isinstance(saved_location, list) and saved_location else saved_location
        
        logger.info(f"Location saved successfully: {saved_location_row.get('id')}")
        return {"message": "Location saved successfully", "location": serialize_saved_location(saved_location_row)}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error saving location: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save location: {str(e)}")

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
    try:
        user_id = current_user["id"]
        db = get_db()
        
        logger.info(f"Deleting location {location_id} for user {user_id}")
        
        # Verify location belongs to user
        user_locations = await db.get_saved_locations(user_id)
        location = next((loc for loc in user_locations if loc["id"] == location_id), None)
        
        if not location:
            logger.warning(f"Location {location_id} not found for user {user_id}")
            raise HTTPException(status_code=404, detail="Location not found")
        
        await db.delete_saved_location(location_id)
        logger.info(f"Location {location_id} deleted successfully")
        return {"message": "Location deleted successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting location: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete location: {str(e)}")
