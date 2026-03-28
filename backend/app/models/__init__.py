"""
Pydantic models for AQI Buddy Backend
Data validation and serialization
"""

from .user import UserProfile
from .aqi import AQIData, AQIForecast, AQIAlert
from .exposure import ExposureRecord, LocationExposure, ExposureTrend, ExposureRecommendation

__all__ = [
    "UserProfile",
    "AQIData", 
    "AQIForecast", 
    "AQIAlert",
    "ExposureRecord", 
    "LocationExposure", 
    "ExposureTrend", 
    "ExposureRecommendation"
]
