"""
AQI Data Models for AQI Buddy Backend
"""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime

class AQIData(BaseModel):
    """AQI data model"""
    
    aqi: int = Field(..., description="Air Quality Index value", ge=0, le=500)
    pm25: Optional[float] = Field(None, description="PM2.5 concentration in μg/m³", ge=0)
    pm10: Optional[float] = Field(None, description="PM10 concentration in μg/m³", ge=0)
    o3: Optional[float] = Field(None, description="Ozone concentration in ppb", ge=0)
    no2: Optional[float] = Field(None, description="Nitrogen dioxide concentration in ppb", ge=0)
    so2: Optional[float] = Field(None, description="Sulfur dioxide concentration in ppb", ge=0)
    co: Optional[float] = Field(None, description="Carbon monoxide concentration in ppm", ge=0)
    
    # Location data
    latitude: float = Field(..., description="Latitude coordinate", ge=-90, le=90)
    longitude: float = Field(..., description="Longitude coordinate", ge=-180, le=180)
    location_name: Optional[str] = Field(None, description="Human-readable location name")
    
    # Metadata
    timestamp: datetime = Field(default_factory=datetime.now, description="Timestamp of the measurement")
    source: Optional[str] = Field(None, description="Data source (e.g., 'openmeteo', 'waqi')")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class AQIForecast(BaseModel):
    """AQI forecast model"""
    
    date: datetime = Field(..., description="Forecast date")
    max_aqi: int = Field(..., description="Maximum AQI for the day", ge=0, le=500)
    avg_aqi: float = Field(..., description="Average AQI for the day", ge=0, le=500)
    min_aqi: int = Field(..., description="Minimum AQI for the day", ge=0, le=500)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }

class AQIAlert(BaseModel):
    """AQI alert model"""
    
    alert_type: str = Field(..., description="Type of alert (e.g., 'high_aqi', 'health_advisory')")
    severity: str = Field(..., description="Severity level (e.g., 'low', 'medium', 'high', 'critical')")
    message: str = Field(..., description="Alert message")
    aqi_value: int = Field(..., description="AQI value that triggered the alert", ge=0, le=500)
    location_name: Optional[str] = Field(None, description="Location name for the alert")
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
