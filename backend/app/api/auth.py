"""
Authentication API routes
Email/password authentication only
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from typing import Dict, Any

from ..core.security import get_current_user, extract_health_sensitivity, extract_display_name
from ..core.database import get_db
from ..models.user import UserProfile

router = APIRouter()

class SignUpRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: str
    health_sensitivity: str = "normal"

class SignInRequest(BaseModel):
    email: EmailStr
    password: str

@router.post("/signup")
async def sign_up(request: SignUpRequest):
    """Sign up new user with email/password"""
    # This would typically call Supabase auth service
    # For now, we'll just return success
    return {
        "message": "User signed up successfully",
        "email": request.email,
        "display_name": request.display_name
    }

@router.post("/signin")
async def sign_in(request: SignInRequest):
    """Sign in user with email/password"""
    # This would typically call Supabase auth service
    # For now, we'll just return success
    return {
        "message": "User signed in successfully",
        "email": request.email
    }

@router.post("/register")
async def register_user(current_user: Dict = Depends(get_current_user)):
    """Register user profile after authentication"""
    user_id = current_user["id"]
    db = get_db()
    
    # Check if profile already exists
    existing_profile = await db.get_user_profile(user_id)
    if existing_profile:
        return {"message": "User already registered", "user_id": user_id}
    
    # Create user profile
    profile_data = {
        "id": user_id,
        "email": current_user.get("email"),
        "phone": current_user.get("phone"),
        "display_name": extract_display_name(current_user),
        "health_sensitivity": extract_health_sensitivity(current_user)
    }
    
    await db.create_user_profile(profile_data)
    
    return {"message": "User registered successfully", "user_id": user_id}
