"""
Database connection and utilities for Supabase
"""

import os
import httpx
from typing import Dict, List, Any, Optional
from datetime import datetime, date
import logging

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
            **user_data,
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
            **profile_data,
            "updated_at": datetime.utcnow().isoformat()
        }
        
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
            **exposure_data,
            "created_at": datetime.utcnow().isoformat()
        }
        
        return await self._make_request("POST", "exposure_history", json=record_data)
    
    async def get_exposure_records(self, user_id: str, days: int = 30) -> List[Dict[str, Any]]:
        """Get user's exposure records for last N days"""
        cutoff_date = (datetime.utcnow() - datetime.timedelta(days=days)).date().isoformat()
        
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
            **location_data,
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
    async def cache_aqi_data(self, aqi_data: Dict[str, Any]) -> Dict[str, Any]:
        """Cache AQI data for 30 minutes"""
        from .config import get_settings
        settings = get_settings()
        
        cache_record = {
            "lat": aqi_data["lat"],
            "lng": aqi_data["lng"],
            "aqi": aqi_data["aqi"],
            "pm25": aqi_data.get("pm25"),
            "pm10": aqi_data.get("pm10"),
            "o3": aqi_data.get("o3"),
            "no2": aqi_data.get("no2"),
            "so2": aqi_data.get("so2"),
            "co": aqi_data.get("co"),
            "location_name": aqi_data.get("location_name"),
            "data_source": aqi_data.get("data_source", "openmeteo"),
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
