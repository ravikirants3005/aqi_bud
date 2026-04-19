"""
Database connection and utilities for Supabase
"""

import os
import logging
from datetime import datetime, date, timedelta
from uuid import uuid4
from typing import Dict, List, Any, Optional

import httpx

logger = logging.getLogger(__name__)

class SupabaseDB:
    """Supabase database client"""
    
    def __init__(self):
        from .config import get_settings
        settings = get_settings()
        
        self.supabase_url = settings.supabase_url
        self.supabase_key = settings.supabase_service_role_key
        
        if not self.supabase_url or not self.supabase_key:
            raise ValueError("Supabase URL and Service Role Key are required")
        
        self.base_url = f"{self.supabase_url}/rest/v1"
        self.headers = {
            "apikey": self.supabase_key,
            "Authorization": f"Bearer {self.supabase_key}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }

    def _new_id(self) -> str:
        return str(uuid4())

    def _first(self, payload: Dict[str, Any], *keys: str, default: Any = None) -> Any:
        for key in keys:
            if key in payload and payload[key] is not None:
                return payload[key]
        return default
    
    async def _make_request(self, method: str, endpoint: str, **kwargs) -> Any:
        """Make HTTP request to Supabase"""
        url = f"{self.base_url}/{endpoint}"
        
        async with httpx.AsyncClient() as client:
            response = await client.request(method, url, headers=self.headers, **kwargs)
            
            if response.status_code >= 400:
                error_text = response.text
                logger.error(f"Supabase API error: {response.status_code} - {error_text}")
                raise Exception(f"Supabase API error: {response.status_code} - {error_text}")
            
            # Return JSON response or empty list for 204 No Content
            if response.status_code == 204:
                return []
            return response.json()
    
    async def test_connection(self) -> bool:
        """Test database connection"""
        try:
            await self._make_request("GET", "users", params={"limit": "1"})
            return True
        except Exception as e:
            logger.error(f"Database connection test failed: {e}")
            raise e
    
    # User Management
    async def create_user_profile(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create user profile in users table"""
        profile_data = {
            "id": self._first(user_data, "id", default=self._new_id()),
            "email": self._first(user_data, "email"),
            "phone": self._first(user_data, "phone"),
            "display_name": self._first(user_data, "display_name", "displayName", default="User"),
            "health_sensitivity": self._first(user_data, "health_sensitivity", "healthSensitivity", default="normal"),
            "age_group": self._first(user_data, "age_group", "ageGroup"),
            "push_token": self._first(user_data, "push_token", "pushToken"),
            "notification_prefs": self._first(user_data, "notification_prefs", "notificationPrefs", default={
                "highAqiAlerts": True,
                "dailyExposureSummary": True,
                "weeklyInsights": True,
                "tipOfDay": False,
            }),
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }
        
        return await self._make_request("POST", "users", json=profile_data)
    
    async def get_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user profile by ID"""
        try:
            result = await self._make_request(
                "GET", 
                "users", 
                params={"id": f"eq.{user_id}", "limit": "1"}
            )
            return result[0] if result else None
        except Exception as e:
            logger.error(f"Error getting user profile: {e}")
            return None
    
    async def update_user_profile(self, user_id: str, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update user profile"""
        update_data = {
            "email": self._first(profile_data, "email"),
            "phone": self._first(profile_data, "phone"),
            "display_name": self._first(profile_data, "display_name", "displayName"),
            "health_sensitivity": self._first(profile_data, "health_sensitivity", "healthSensitivity"),
            "age_group": self._first(profile_data, "age_group", "ageGroup"),
            "push_token": self._first(profile_data, "push_token", "pushToken"),
            "notification_prefs": self._first(profile_data, "notification_prefs", "notificationPrefs"),
            "updated_at": datetime.utcnow().isoformat()
        }

        if self._first(profile_data, "notification_prefs", "notificationPrefs") is None:
            update_data.pop("notification_prefs")

        if self._first(profile_data, "email") is None:
            update_data.pop("email")
        if self._first(profile_data, "phone") is None:
            update_data.pop("phone")
        if self._first(profile_data, "display_name", "displayName") is None:
            update_data.pop("display_name")
        if self._first(profile_data, "health_sensitivity", "healthSensitivity") is None:
            update_data.pop("health_sensitivity")
        if self._first(profile_data, "age_group", "ageGroup") is None:
            update_data.pop("age_group")
        if self._first(profile_data, "push_token", "pushToken") is None:
            update_data.pop("push_token")
        
        return await self._make_request(
            "PATCH",
            "users",
            params={"id": f"eq.{user_id}"},
            json=update_data
        )
    
    # Exposure Records
    async def create_exposure_record(self, exposure_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create exposure record"""
        record_data = {
            "id": self._first(exposure_data, "id", default=self._new_id()),
            "user_id": self._first(exposure_data, "user_id", "userId"),
            "date": self._first(exposure_data, "date", "record_date", "recordDate"),
            "score": self._first(exposure_data, "score", "total_exposure_score", "totalExposureScore", default=0),
            "max_aqi": self._first(exposure_data, "max_aqi", "maxAqi", default=0),
            "outdoor_minutes": self._first(exposure_data, "outdoor_minutes", "outdoorMinutes", default=0),
            "location_exposures": self._first(exposure_data, "location_exposures", "locationExposures", default=[]),
            "created_at": datetime.utcnow().isoformat()
        }
        
        return await self._make_request("POST", "exposure_history", json=record_data)
    
    async def get_exposure_records(self, user_id: str, days: int = 30) -> List[Dict[str, Any]]:
        """Get user's exposure records for last N days"""
        cutoff_date = (datetime.utcnow() - timedelta(days=days)).date().isoformat()
        
        return await self._make_request(
            "GET",
            "exposure_history",
            params={
                "user_id": f"eq.{user_id}",
                "date": f"gte.{cutoff_date}",
                "order": "date.desc"
            }
        )
    
    # Saved Locations
    async def create_saved_location(self, location_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create saved location"""
        location_record = {
            "id": self._first(location_data, "id", default=self._new_id()),
            "user_id": self._first(location_data, "user_id", "userId"),
            "name": self._first(location_data, "name", default="Saved location"),
            "lat": self._first(location_data, "lat"),
            "lng": self._first(location_data, "lng"),
            "last_aqi": self._first(location_data, "last_aqi", "lastAqi"),
            "last_updated": self._first(location_data, "last_updated", "lastUpdated"),
            "created_at": datetime.utcnow().isoformat()
        }
        
        return await self._make_request("POST", "saved_locations", json=location_record)
    
    async def get_saved_locations(self, user_id: str) -> List[Dict[str, Any]]:
        """Get user's saved locations"""
        return await self._make_request(
            "GET",
            "saved_locations",
            params={
                "user_id": f"eq.{user_id}",
                "order": "created_at.desc"
            }
        )
    
    async def delete_saved_location(self, location_id: str) -> None:
        """Delete saved location"""
        await self._make_request(
            "DELETE",
            "saved_locations",
            params={"id": f"eq.{location_id}"}
        )
    
    # AQI Cache
    async def cache_aqi_data(self, aqi_data) -> Dict[str, Any]:
        """Cache AQI data for 30 minutes - accepts dict or AQIData model"""
        from .config import get_settings
        settings = get_settings()
        
        # Handle both dict and AQIData model
        if hasattr(aqi_data, 'dict'):
            # Pydantic model
            data = aqi_data.dict()
        elif hasattr(aqi_data, 'model_dump'):
            # Pydantic v2
            data = aqi_data.model_dump()
        else:
            # Dict
            data = aqi_data
        
        cache_record = {
            "lat": data.get("latitude") if isinstance(data, dict) else getattr(aqi_data, 'latitude', None),
            "lng": data.get("longitude") if isinstance(data, dict) else getattr(aqi_data, 'longitude', None),
            "aqi": data.get("aqi") if isinstance(data, dict) else getattr(aqi_data, 'aqi', None),
            "pm25": data.get("pm25") if isinstance(data, dict) else getattr(aqi_data, 'pm25', None),
            "pm10": data.get("pm10") if isinstance(data, dict) else getattr(aqi_data, 'pm10', None),
            "o3": data.get("o3") if isinstance(data, dict) else getattr(aqi_data, 'o3', None),
            "no2": data.get("no2") if isinstance(data, dict) else getattr(aqi_data, 'no2', None),
            "so2": data.get("so2") if isinstance(data, dict) else getattr(aqi_data, 'so2', None),
            "co": data.get("co") if isinstance(data, dict) else getattr(aqi_data, 'co', None),
            "location_name": data.get("location_name") if isinstance(data, dict) else getattr(aqi_data, 'location_name', None),
            "data_source": data.get("source", "openmeteo") if isinstance(data, dict) else getattr(aqi_data, 'source', "openmeteo"),
            "cached_at": datetime.utcnow().isoformat(),
            "expires_at": (datetime.utcnow() + datetime.timedelta(minutes=settings.aqi_cache_ttl_minutes)).isoformat()
        }
        
        return await self._make_request("POST", "aqi_cache", json=cache_record)
    
    async def get_cached_aqi_data(self, lat: float, lng: float) -> Optional[Dict[str, Any]]:
        """Get cached AQI data if not expired"""
        try:
            # Round coordinates to 4 decimal places for better cache hits
            lat_rounded = round(lat, 4)
            lng_rounded = round(lng, 4)
            
            result = await self._make_request(
                "GET",
                "aqi_cache",
                params={
                    "lat": f"eq.{lat_rounded}",
                    "lng": f"eq.{lng_rounded}",
                    "expires_at": f"gt.{datetime.utcnow().isoformat()}",
                    "limit": "1",
                    "order": "cached_at.desc"
                }
            )
            
            return result[0] if result else None
        except Exception:
            return None

# Database dependency
def get_db() -> SupabaseDB:
    """Get database instance"""
    return SupabaseDB()
