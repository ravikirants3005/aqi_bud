"""
User-related Pydantic models
"""

from pydantic import BaseModel, EmailStr
from typing import Optional, Dict

class UserProfile(BaseModel):
    id: str
    email: Optional[str] = None
    phone: Optional[str] = None
    display_name: str
    health_sensitivity: str = "normal"
    age_group: Optional[str] = None
    push_token: Optional[str] = None
    notification_prefs: Dict[str, bool] = {
        "high_aqi_alerts": True,
        "daily_exposure_summary": True,
        "weekly_insights": True,
        "tip_of_day": False
    }
