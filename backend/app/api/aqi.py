"""
AQI Data API routes
Current AQI data and forecasting
"""

from fastapi import APIRouter, Depends, Query
from typing import Dict, Any, List

from ..core.security import get_current_user, extract_health_sensitivity, extract_notification_prefs
from ..core.database import get_db
from ..services.aqi_service import AQIService
from ..services.notification_service import NotificationService

router = APIRouter()

# Initialize services
aqi_service = AQIService()
notification_service = NotificationService()

@router.get("/current")
async def get_current_aqi(
    lat: float = Query(..., description="Latitude"),
    lng: float = Query(..., description="Longitude"),
    current_user: Dict = Depends(get_current_user)
):
    """Get current AQI for location"""
    try:
        db = get_db()
        aqi_data = await aqi_service.get_current_aqi(lat, lng)
        
        # Get user preferences
        user_id = current_user["id"]
        profile = await db.get_user_profile(user_id)
        notification_prefs = extract_notification_prefs(current_user)
        health_sensitivity = extract_health_sensitivity(current_user)
        
        # Check for high AQI alerts
        threshold = {
            "normal": 150,
            "sensitive": 100,
            "asthmatic": 75,
            "elderly": 75
        }.get(health_sensitivity, 150)
        
        if aqi_data.aqi >= threshold and notification_prefs.get("high_aqi_alerts", True):
            await notification_service.send_high_aqi_alert(current_user, aqi_data)
        
        return aqi_data
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to fetch AQI data")

@router.get("/forecast")
async def get_aqi_forecast(
    lat: float = Query(..., description="Latitude"),
    lng: float = Query(..., description="Longitude"),
    days: int = Query(7, ge=1, le=30, description="Number of days to forecast"),
    current_user: Dict = Depends(get_current_user)
):
    """Get AQI forecast for location"""
    try:
        forecast = await aqi_service.get_aqi_forecast(lat, lng, days)
        return {"forecast": forecast}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to fetch forecast")
