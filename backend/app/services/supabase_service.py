"""
Supabase integration service
User management and data operations
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, date

from ..core.database import get_db

class SupabaseService:
    """Supabase service for user management"""
    
    def __init__(self):
        self.db = get_db()
    
    async def test_connection(self) -> bool:
        """Test Supabase connection"""
        return await self.db.test_connection()
    
    async def create_user_profile(self, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create user profile"""
        return await self.db.create_user_profile(user_data)
    
    async def get_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user profile"""
        return await self.db.get_user_profile(user_id)
    
    async def update_user_profile(self, user_id: str, profile_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update user profile"""
        return await self.db.update_user_profile(user_id, profile_data)
    
    async def get_user_analytics(self, user_id: str) -> Dict[str, Any]:
        """Get user analytics data"""
        # Get recent exposure records
        recent_exposures = await self.db.get_exposure_records(user_id, days=30)
        
        # Get saved locations count
        saved_locations = await self.db.get_saved_locations(user_id)
        
        # Calculate analytics
        if recent_exposures:
            avg_exposure = sum(r["score"] for r in recent_exposures) / len(recent_exposures)
            high_exposure_days = len([r for r in recent_exposures if r["score"] >= 60])
        else:
            avg_exposure = 0
            high_exposure_days = 0
        
        return {
            "avg_exposure_score_30_days": avg_exposure,
            "high_exposure_days_30": high_exposure_days,
            "saved_locations_count": len(saved_locations),
            "total_exposure_records": len(recent_exposures)
        }
