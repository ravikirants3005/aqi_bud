-- AQI Buddy Supabase Database Schema
-- Run this in Supabase SQL Editor

-- Create tables for AQI Buddy app

-- User profiles
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE,
    phone TEXT UNIQUE,
    display_name TEXT NOT NULL,
    health_sensitivity TEXT DEFAULT 'normal' CHECK (health_sensitivity IN ('normal', 'sensitive', 'asthmatic', 'elderly')),
    age_group TEXT,
    notification_prefs JSONB DEFAULT '{"high_aqi_alerts": true, "daily_exposure_summary": true, "weekly_insights": true, "tip_of_day": false}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exposure records
CREATE TABLE IF NOT EXISTS exposure_history (
    id TEXT PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    score FLOAT NOT NULL CHECK (score >= 0 AND score <= 100),
    max_aqi INTEGER NOT NULL CHECK (max_aqi >= 0),
    outdoor_minutes INTEGER NOT NULL CHECK (outdoor_minutes >= 0),
    location_exposures JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Saved locations
CREATE TABLE IF NOT EXISTS saved_locations (
    id TEXT PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    lat FLOAT NOT NULL,
    lng FLOAT NOT NULL,
    last_aqi INTEGER,
    last_updated TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AQI cache
CREATE TABLE IF NOT EXISTS aqi_cache (
    id SERIAL PRIMARY KEY,
    lat FLOAT NOT NULL,
    lng FLOAT NOT NULL,
    aqi INTEGER NOT NULL,
    pm25 FLOAT,
    pm10 FLOAT,
    o3 FLOAT,
    no2 FLOAT,
    so2 FLOAT,
    co FLOAT,
    location_name TEXT,
    data_source TEXT DEFAULT 'openmeteo',
    cached_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_exposure_history_user_date ON exposure_history(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_saved_locations_user ON saved_locations(user_id);
CREATE INDEX IF NOT EXISTS idx_aqi_cache_coords ON aqi_cache(lat, lng);
CREATE INDEX IF NOT EXISTS idx_aqi_cache_expires ON aqi_cache(expires_at);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE exposure_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE aqi_cache ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can only access their own profile
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid()::text = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid()::text = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid()::text = id);

-- Users can only access their own exposure records
CREATE POLICY "Users can view own exposure records" ON exposure_history FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can insert own exposure records" ON exposure_history FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update own exposure records" ON exposure_history FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete own exposure records" ON exposure_history FOR DELETE USING (auth.uid()::text = user_id);

-- Users can only access their own saved locations
CREATE POLICY "Users can view own saved locations" ON saved_locations FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can insert own saved locations" ON saved_locations FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update own saved locations" ON saved_locations FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete own saved locations" ON saved_locations FOR DELETE USING (auth.uid()::text = user_id);

-- AQI cache is public (no sensitive data)
CREATE POLICY "AQI cache is publicly readable" ON aqi_cache FOR SELECT USING (true);
CREATE POLICY "Anyone can insert AQI cache" ON aqi_cache FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update AQI cache" ON aqi_cache FOR UPDATE WITH CHECK (true);

-- Function to automatically update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
