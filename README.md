# AQI Buddy

Air Quality monitoring app with health insights and exposure tracking.

## 🏗️ Architecture

```
aqi_bud/
├── 📱 lib/                     # Flutter mobile app
│   ├── core/                  # Core utilities and configurations
│   ├── data/                  # Data layer (APIs, models, repositories)
│   ├── domain/                # Business logic (providers)
│   ├── features/              # Feature modules (auth, profile, home, etc.)
│   └── main.dart             # App entry point
├── 🔧 backend/                # Python FastAPI backend
│   ├── app/                   # Main application code
│   ├── config/                # Configuration files
│   ├── scripts/               # Utility scripts
│   └── requirements.txt       # Python dependencies
└── README.md                 # This file
```

## 🚀 Quick Start

### Backend Setup

```bash
cd backend

# Copy environment template
cp config/.env.example .env

# Edit .env with your Supabase credentials
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Install dependencies and start server
pip install -r requirements.txt
python scripts/start.py
```

### Frontend Setup

```bash
# Install Flutter dependencies
flutter pub get

# Configure Supabase in lib/supabase_options.dart
# Add your Supabase URL and anon key

# Run the app
flutter run
```

## 📡 Features

- ✅ **Authentication**: Email, Google, Phone OTP via Supabase
- ✅ **AQI Monitoring**: Real-time air quality data
- ✅ **Exposure Tracking**: Daily exposure scoring and insights
- ✅ **Location Management**: Save and monitor favorite locations
- ✅ **Health Insights**: Personalized recommendations
- ✅ **Notifications**: High AQI alerts and daily summaries

## 🔧 Configuration

### Supabase Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Run the SQL schema from `backend/config/database.sql`
3. Configure authentication providers
4. Get your project URL and keys

### Environment Variables

**Backend (.env):**
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for backend

**Flutter (lib/supabase_options.dart):**
- `url` - Your Supabase project URL
- `anonKey` - Public anon key for frontend

## 📊 Database Schema

### Tables
- **users** - User profiles and preferences
- **exposure_history** - Daily exposure tracking
- **saved_locations** - User's favorite locations
- **aqi_cache** - Cached AQI data

## 🧪 Testing

```bash
# Backend tests
cd backend
pytest

# Flutter tests
flutter test
```

## 🐳 Docker

```bash
# Backend
cd backend
docker build -t aqi-buddy-backend .
docker run -p 8000:8000 --env-file .env aqi-buddy-backend
```

## 📱 API Documentation

Backend API docs available at `http://localhost:8000/docs`

## 🔒 Security

- JWT authentication via Supabase
- Row Level Security (RLS) policies
- CORS configuration
- Input validation

---

**Built with ❤️ using Flutter, FastAPI, and Supabase**
