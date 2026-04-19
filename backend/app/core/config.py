"""
Configuration settings for AQI Buddy Backend
"""

import os
import json
from pydantic_settings import BaseSettings
from pydantic import field_validator
from typing import List, Optional

class Settings(BaseSettings):
    """Application settings"""
    
    # Supabase Configuration
    supabase_url: str
    supabase_service_role_key: str
    
    # API Configuration
    api_title: str = "AQI Buddy API"
    api_version: str = "1.0.0"
    debug: bool = False
    
    # CORS Configuration
    allowed_origins: List[str] = ["http://localhost:3000", "http://localhost:8000"]
    
    @field_validator('allowed_origins', mode='before')
    @classmethod
    def parse_allowed_origins(cls, v):
        """Parse ALLOWED_ORIGINS from JSON string or comma-separated string"""
        if isinstance(v, str):
            try:
                # Try JSON format: ["http://localhost:3000", ...]
                return json.loads(v)
            except json.JSONDecodeError:
                # Try comma-separated format: http://localhost:3000,http://localhost:8000
                return [origin.strip() for origin in v.split(',')]
        return v
    
    # Push Notification Configuration
    push_notifications_enabled: bool = True
    onesignal_app_id: Optional[str] = None
    onesignal_rest_api_key: Optional[str] = None
    firebase_server_key: Optional[str] = None
    
    # AQI API Configuration
    openmeteo_url: str = "https://air-quality-api.open-meteo.com/v1/air-quality"
    aqicn_url: str = "https://api.waqi.info/feed"
    
    # Cache Configuration
    aqi_cache_ttl_minutes: int = 30
    
    # Logging Configuration
    log_level: str = "INFO"
    
    # External API Keys
    aqi_api_key: Optional[str] = None
    openaq_api_key: Optional[str] = None
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields from .env

def get_settings() -> Settings:
    """Get application settings"""
    return Settings()
