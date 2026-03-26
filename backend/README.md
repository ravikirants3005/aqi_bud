# AQI Buddy Backend

Clean FastAPI backend for AQI Buddy mobile app with Supabase integration.

## 🏗️ Architecture

```
backend/
├── app/                    # Main application code
│   ├── api/               # API routes (auth, aqi, exposure, locations, users)
│   ├── core/              # Core functionality (config, database, security)
│   ├── models/            # Pydantic models
│   ├── services/          # Business services (AQI, notifications, Supabase)
│   └── main.py           # FastAPI entry point
├── config/               # Configuration files
│   ├── .env.example      # Environment variables template
│   └── database.sql      # Database schema
├── scripts/              # Utility scripts
│   └── start.py         # Server startup script
├── tests/               # Test files
├── requirements.txt     # Python dependencies
└── README.md           # This file
```

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Copy environment template
cp config/.env.example .env

# Edit .env with your Supabase credentials
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 2. Database Setup

Run the SQL schema in Supabase SQL Editor:
```bash
# Copy and run config/database.sql in Supabase
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Start Server

```bash
# Use startup script
python scripts/start.py

# Or direct start
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 📡 API Endpoints

### Authentication
- `POST /auth/register` - Register user profile
- `GET /user/profile` - Get user profile
- `PUT /user/profile` - Update user profile
- `GET /user/analytics` - Get user analytics

### AQI Data
- `GET /aqi/current?lat=X&lng=Y` - Get current AQI
- `GET /aqi/forecast?lat=X&lng=Y&days=7` - Get AQI forecast

### Exposure Tracking
- `POST /exposure/record` - Record daily exposure
- `GET /exposure/history?days=30` - Get exposure history

### Location Management
- `POST /locations/save` - Save location
- `GET /locations/saved` - Get saved locations
- `DELETE /locations/{id}` - Delete location

### System
- `GET /health` - Health check
- `GET /docs` - API documentation (Swagger UI)

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | Required |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | Required |
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:3000,http://localhost:8000` |
| `PUSH_NOTIFICATIONS_ENABLED` | Enable push notifications | `false` |
| `FIREBASE_SERVER_KEY` | Firebase server key | Optional |
| `AQI_CACHE_TTL_MINUTES` | AQI cache TTL | `30` |
| `LOG_LEVEL` | Logging level | `INFO` |

## 🏛️ Database Schema

### Tables
- **users** - User profiles and preferences
- **exposure_history** - Daily exposure tracking
- **saved_locations** - User's favorite monitoring locations
- **aqi_cache** - Cached AQI data (30min TTL)

## 🧪 Testing

```bash
pytest
pytest --cov=app tests/
```

## 🐳 Docker

```bash
docker build -t aqi-buddy-backend .
docker run -p 8000:8000 --env-file .env aqi-buddy-backend
```

## 📊 Monitoring

- `GET /health` - Database connection status
- Application logs available via stdout

## 🔒 Security

- JWT token validation with Supabase
- Row Level Security (RLS) policies
- CORS configuration
- Input validation with Pydantic

## 🚀 Development

### Adding New Endpoints

1. Create Pydantic model in `app/models/`
2. Add business logic in `app/services/`
3. Create API route in `app/api/`
4. Include router in `app/main.py`

## 📝 Flutter Integration

1. User authenticates via Supabase in Flutter
2. Flutter app gets JWT token
3. App calls backend API with `Authorization: Bearer <token>`
4. Backend validates token with Supabase
5. Backend processes request using user's Supabase ID

---

**Built with FastAPI and Supabase**
