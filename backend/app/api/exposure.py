"""
Exposure tracking API routes
Daily exposure records and history
"""

from fastapi import APIRouter, Depends, Query, HTTPException
from typing import List, Dict, Any
import logging

from ..core.security import get_current_user, extract_notification_prefs
from ..core.database import get_db
from ..services.notification_service import NotificationService
from ..core.serializers import normalize_exposure_payload, serialize_exposure_record

router = APIRouter()
notification_service = NotificationService()
logger = logging.getLogger(__name__)

@router.post("/record")
async def record_exposure(exposure_data: Dict[str, Any], current_user: Dict = Depends(get_current_user)):
    """Record daily exposure data"""
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
        
        # Add user_id to exposure data from authenticated token and normalize
        exposure_data["user_id"] = user_id
        normalized_exposure = normalize_exposure_payload(exposure_data, user_id=user_id)

        # Create exposure record
        record = await db.create_exposure_record(normalized_exposure)
        
        # Get user preferences for notifications
        notification_prefs = extract_notification_prefs(current_user)
        
        # Send daily summary if enabled
        if notification_prefs.get("daily_exposure_summary", True):
            await notification_service.send_daily_summary(current_user, normalized_exposure)
        
        record_row = record[0] if isinstance(record, list) and record else record
        return {"message": "Exposure recorded successfully", "exposure": serialize_exposure_record(record_row)}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error recording exposure: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to record exposure: {str(e)}")

@router.get("/history")
async def get_exposure_history(
    days: int = Query(30, ge=1, le=365, description="Number of days to fetch"),
    current_user: Dict = Depends(get_current_user)
):
    """Get user's exposure history"""
    user_id = current_user["id"]
    db = get_db()
    exposures = await db.get_exposure_records(user_id, days)
    return {"exposures": [serialize_exposure_record(exposure) for exposure in exposures]}
