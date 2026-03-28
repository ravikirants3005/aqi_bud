"""
AQI data service
Integration with external AQI APIs
"""

import aiohttp
from typing import List, Dict, Any
from datetime import datetime

from ..core.config import get_settings
from ..core.database import get_db

class AQIService:
    """AQI data service"""
    
    def __init__(self):
        settings = get_settings()
        self.open_meteo_url = settings.openmeteo_url
        self.db = get_db()
    
    async def get_current_aqi(self, lat: float, lng: float):
        """Get current AQI data from Open-Meteo API"""
        # Check cache first
        cached_data = await self.db.get_cached_aqi_data(lat, lng)
        if cached_data:
            return cached_data
        
        # Fetch fresh data
        params = {
            "latitude": lat,
            "longitude": lng,
            "current": "pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,uv_index, european_aqi,us_aqi"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.get(self.open_meteo_url, params=params) as response:
                if response.status != 200:
                    raise Exception("Failed to fetch AQI data")
                
                data = await response.json()
                current = data.get("current", {})
                
                aqi_data = {
                    "aqi": current.get("us_aqi", current.get("european_aqi", 50)),
                    "lat": lat,
                    "lng": lng,
                    "pm25": current.get("pm2_5"),
                    "pm10": current.get("pm10"),
                    "o3": current.get("ozone"),
                    "no2": current.get("nitrogen_dioxide"),
                    "so2": current.get("sulphur_dioxide"),
                    "co": current.get("carbon_monoxide"),
                    "timestamp": datetime.now().isoformat()
                }
                
                # Cache the data
                await self.db.cache_aqi_data(aqi_data)
                
                return aqi_data
    
    async def get_aqi_forecast(self, lat: float, lng: float, days: int = 7) -> List[Dict]:
        """Get AQI forecast for next N days"""
        params = {
            "latitude": lat,
            "longitude": lng,
            "hourly": "pm10,pm2_5,us_aqi",
            "forecast_hours": days * 24  # Convert days to hours
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.get(self.open_meteo_url, params=params) as response:
                if response.status != 200:
                    raise Exception("Failed to fetch forecast")
                
                data = await response.json()
                hourly = data.get("hourly", {})
                
                # Process hourly data into daily averages
                daily_forecast = []
                time_data = hourly.get("time", [])
                aqi_data = hourly.get("us_aqi", [])
                
                if time_data and aqi_data:
                    # Group by date
                    daily_groups = {}
                    for i, time_str in enumerate(time_data[:24*days]):
                        date_str = time_str.split("T")[0]
                        if date_str not in daily_groups:
                            daily_groups[date_str] = []
                        if i < len(aqi_data):
                            daily_groups[date_str].append(aqi_data[i])
                    
                    # Calculate daily averages
                    for date_str, values in daily_groups.items():
                        avg_aqi = sum(v for v in values if v is not None) / len(values) if values else 50
                        daily_forecast.append({
                            "date": date_str,
                            "avg_aqi": avg_aqi,
                            "max_aqi": max(v for v in values if v is not None) if values else 50
                        })
                
                return daily_forecast
