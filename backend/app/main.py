"""
AQI Buddy Backend - Main FastAPI Application
Clean, modular FastAPI backend with Supabase integration
"""

from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any
import asyncio
import datetime
import os
from dotenv import load_dotenv
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="AQI Buddy API",
    description="Backend for AQI Buddy - Air Quality monitoring with Supabase",
    version="1.0.0"
)

# CORS middleware
origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Import modules
from .core.config import get_settings
from .core.database import get_db
from .core.security import get_current_user
from .models.user import UserProfile
from .models.aqi import AQIData
from .models.exposure import ExposureRecord
from .services.aqi_service import AQIService
from .services.notification_service import NotificationService
from .services.supabase_service import SupabaseService

# Initialize services
settings = get_settings()
aqi_service = AQIService()
notification_service = NotificationService()
supabase_service = SupabaseService()

# API Routes
from .api.auth import router as auth_router
from .api.aqi import router as aqi_router
from .api.exposure import router as exposure_router
from .api.locations import router as locations_router
from .api.users import router as users_router

# Include routers
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(aqi_router, prefix="/aqi", tags=["AQI Data"])
app.include_router(exposure_router, prefix="/exposure", tags=["Exposure Tracking"])
app.include_router(locations_router, prefix="/locations", tags=["Location Management"])
app.include_router(users_router, prefix="/user", tags=["User Management"])

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "AQI Buddy Backend API",
        "version": "1.0.0",
        "database": "Supabase",
        "docs": "/docs",
        "health": "/health"
    }

# Health check
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test Supabase connection
        await supabase_service.test_connection()
        return {
            "status": "healthy",
            "database": "Supabase connected",
            "timestamp": datetime.datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": datetime.datetime.now().isoformat()
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True if os.getenv("ENVIRONMENT") == "development" else False
    )
