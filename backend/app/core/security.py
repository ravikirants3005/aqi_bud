"""
Security utilities for authentication and authorization
"""

import os
import httpx
import jwt
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

security = HTTPBearer()

class SupabaseAuth:
    """Supabase authentication service"""
    
    def __init__(self):
        from .config import get_settings
        settings = get_settings()
        
        self.supabase_url = settings.supabase_url
        self.supabase_key = settings.supabase_service_role_key
        
        if not self.supabase_url or not self.supabase_key:
            print("Warning: Supabase credentials not found in environment variables")
    
    async def verify_token(self, token: str) -> Dict[str, Any]:
        """Verify JWT token with Supabase"""
        if not self.supabase_url or not self.supabase_key:
            # Fallback to mock verification for development
            return self._mock_verify_token(token)
        
        try:
            # Get JWKS from Supabase
            jwks_url = f"{self.supabase_url}/auth/v1/.well-known/jwks.json"
            
            async with httpx.AsyncClient() as client:
                response = await client.get(jwks_url)
                if response.status_code != 200:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Failed to verify token"
                    )
                
                jwks = response.json()
                
                # Decode JWT token
                header = jwt.get_unverified_header(token)
                key_id = header.get("kid")
                
                # Find matching key
                key = None
                for jwk in jwks.get("keys", []):
                    if jwk.get("kid") == key_id:
                        key = jwt.algorithms.RSAAlgorithm.from_jwk(jwk)
                        break
                
                if not key:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid token signature"
                    )
                
                # Verify token
                payload = jwt.decode(
                    token,
                    key,
                    algorithms=["RS256"],
                    audience="authenticated",
                    issuer=f"{self.supabase_url}/auth/v1"
                )
                
                return payload
                
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired"
            )
        except jwt.InvalidTokenError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid token: {str(e)}"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Token verification failed: {str(e)}"
            )
    
    def _mock_verify_token(self, token: str) -> Dict[str, Any]:
        """Mock token verification for development"""
        try:
            # Try to decode without verification for mock
            payload = jwt.decode(token, options={"verify_signature": False})
            
            # Add mock user data if not present
            if "sub" not in payload:
                payload["sub"] = "mock_user_id"
                payload["email"] = "mock@example.com"
                payload["user_metadata"] = {
                    "display_name": "Mock User",
                    "health_sensitivity": "normal"
                }
            
            return payload
            
        except Exception:
            # Return mock payload for any token format
            return {
                "sub": "mock_user_id",
                "email": "mock@example.com",
                "user_metadata": {
                    "display_name": "Mock User",
                    "health_sensitivity": "normal",
                    "age_group": None
                },
                "aud": "authenticated",
                "created_at": "2024-01-01T00:00:00Z"
            }
    
    async def get_user_from_token(self, token: str) -> Dict[str, Any]:
        """Get user profile from Supabase using token"""
        if not self.supabase_url or not self.supabase_key:
            return self._mock_get_user(token)
        
        try:
            headers = {
                "Authorization": f"Bearer {token}",
                "apikey": self.supabase_key
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.supabase_url}/auth/v1/user",
                    headers=headers
                )
                
                if response.status_code != 200:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Failed to get user data"
                    )
                
                return response.json()
                
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Failed to get user: {str(e)}"
            )
    
    def _mock_get_user(self, token: str) -> Dict[str, Any]:
        """Mock user data for development"""
        return {
            "id": "mock_user_id",
            "email": "mock@example.com",
            "user_metadata": {
                "display_name": "Mock User",
                "health_sensitivity": "normal",
                "age_group": None
            },
            "app_metadata": {},
            "aud": "authenticated",
            "created_at": "2024-01-01T00:00:00Z"
        }

# Initialize auth service
supabase_auth = SupabaseAuth()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """FastAPI dependency to get current authenticated user"""
    token = credentials.credentials
    
    try:
        # Verify token and get user data
        user_data = await supabase_auth.get_user_from_token(token)
        return user_data
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )

async def get_user_id(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    """Get just the user ID from token"""
    user = await get_current_user(credentials)
    return user.get("id", "")

# Utility functions
def extract_health_sensitivity(user_data: Dict[str, Any]) -> str:
    """Extract health sensitivity from user metadata"""
    metadata = user_data.get("user_metadata", {})
    return metadata.get("health_sensitivity") or metadata.get("healthSensitivity") or "normal"

def extract_display_name(user_data: Dict[str, Any]) -> str:
    """Extract display name from user metadata"""
    metadata = user_data.get("user_metadata", {})
    return metadata.get("display_name") or metadata.get("displayName") or user_data.get("email", "User")

def extract_notification_prefs(user_data: Dict[str, Any]) -> Dict[str, bool]:
    """Extract notification preferences from user metadata"""
    metadata = user_data.get("user_metadata", {})
    return {
        "high_aqi_alerts": metadata.get("high_aqi_alerts", metadata.get("highAqiAlerts", True)),
        "daily_exposure_summary": metadata.get("daily_exposure_summary", metadata.get("dailyExposureSummary", True)),
        "weekly_insights": metadata.get("weekly_insights", metadata.get("weeklyInsights", True)),
        "tip_of_day": metadata.get("tip_of_day", metadata.get("tipOfDay", False))
    }
