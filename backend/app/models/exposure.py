"""
Exposure Tracking Models for AQI Buddy Backend
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime, date, time, timedelta

class LocationExposure(BaseModel):
    """Location-based exposure data"""
    
    latitude: float = Field(..., description="Latitude coordinate", ge=-90, le=90)
    longitude: float = Field(..., description="Longitude coordinate", ge=-180, le=180)
    location_name: Optional[str] = Field(None, description="Human-readable location name")
    aqi: int = Field(..., description="AQI value at this location", ge=0, le=500)
    duration_minutes: int = Field(..., description="Duration spent at location in minutes", ge=0)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            date: lambda v: v.isoformat(),
            time: lambda v: v.isoformat(),
        }

class ExposureRecord(BaseModel):
    """Daily exposure tracking record"""
    
    user_id: str = Field(..., description="User ID who owns this record")
    record_date: date = Field(..., description="Date of exposure tracking")
    total_exposure_score: float = Field(..., description="Total exposure score for the day", ge=0, le=100)
    max_aqi: int = Field(..., description="Maximum AQI encountered during the day", ge=0, le=500)
    outdoor_minutes: int = Field(default=0, description="Total outdoor minutes", ge=0)
    location_exposures: List[LocationExposure] = Field(default_factory=list, description="Detailed location exposure data")
    
    # Calculated fields
    safe_limit_percentage: Optional[float] = Field(None, description="Percentage of safe limit used", ge=0, le=200)
    health_risk_level: Optional[str] = Field(None, description="Health risk level for the day")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            date: lambda v: v.isoformat(),
            time: lambda v: v.isoformat(),
        }

class ExposureTrend(BaseModel):
    """Exposure trend analysis"""
    
    period_days: int = Field(..., description="Number of days in the trend analysis", ge=1)
    average_exposure_score: float = Field(..., description="Average exposure score", ge=0, le=100)
    high_aqi_days: int = Field(..., description="Number of days with AQI > 100", ge=0)
    trend_direction: str = Field(..., description="Trend direction (improving, worsening, stable)")
    weekly_pattern: Dict[str, Any] = Field(default_factory=dict, description="Weekly exposure patterns")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            date: lambda v: v.isoformat(),
            time: lambda v: v.isoformat(),
        }

class ExposureRecommendation(BaseModel):
    """Personalized exposure recommendations"""
    
    recommendation_type: str = Field(..., description="Type of recommendation")
    title: str = Field(..., description="Recommendation title")
    description: str = Field(..., description="Detailed recommendation")
    priority: str = Field(..., description="Priority level (low, medium, high)")
    actionable: bool = Field(default=True, description="Whether the recommendation is actionable")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            date: lambda v: v.isoformat(),
            time: lambda v: v.isoformat(),
        }
