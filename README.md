# AQI Buddy

**Air Quality Awareness, Health Insights & Exposure Tracking**

By Vayu Aarambh Innovations Pvt. Ltd.

---

## Overview

AQI Buddy is an Android mobile application that helps users:

- Understand real-time air pollution around them
- Get precautions before, during, and after outdoor exposure
- Track daily pollution exposure
- View personalized insights based on lifestyle, location, and health category
- Learn about air pollution and its health effects

## Requirements Coverage

| SRS Feature | Status |
|-------------|--------|
| **4.1 AQI Panel** | ✅ GPS-based AQI, 30-min update, EPA/WHO categories, 7-day trend, worst days |
| **4.2 Suggestions** | ✅ Pre/during/post advice per AQI category |
| **4.3 Health Tips** | ✅ Breathing, yoga, walking, lung health; animations |
| **4.4 User Profile** | ✅ Health sensitivity, notifications, saved locations (UI) |
| **4.5 Exposure Insights** | ✅ Score 0-100, weekly/monthly patterns, high-exposure alerts |
| **4.6 Education Module** | ✅ What is AQI, pollutants, health effects |
| **5.x Nonfunctional** | ✅ Medical disclaimer, performance targets |
| **6.x Other** | ✅ Caching, API rate limits, GDPR-ready structure |

## Tech Stack

- **Flutter** (Dart)
- **Open-Meteo Air Quality API** (free, no key)
- **Riverpod** for state management
- **go_router** for navigation
- **Material Design 3**
- **geolocator** / **geocoding** for location

## Setup

1. **Prerequisites**: Flutter SDK 3.11+
2. **Install**:
   ```bash
   cd aqi_bud
   flutter pub get
   ```
3. **Run**:
   ```bash
   flutter run
   ```

## Firebase Setup (Google Sign-In & Phone OTP)

Firebase is included for **Google Sign-In** and **Phone OTP** authentication. Email+Password works with local storage if Firebase is not configured.

### 1. Prerequisites

- Node.js (for Firebase CLI)
- A Google account

### 2. Install Firebase & FlutterFire CLI

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

### 3. Login to Firebase

```bash
firebase login
```

### 4. Configure FlutterFire

From the project root:

```bash
flutterfire configure
```

This will:

- Create or link a Firebase project
- Add Android/Web apps
- Generate `lib/firebase_options.dart` with your config
- Update `android/app/google-services.json`

### 5. Enable Auth Methods (Firebase Console)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. **Authentication** → **Sign-in method**
4. Enable **Email/Password**
5. Enable **Google** (add support email if prompted)
6. Enable **Phone** (no extra config for testing)

### 6. Google Sign-In (Android)

For release builds, add your SHA-1 in Firebase Console:

1. **Project settings** → **Your apps** → Android app
2. Add SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey`
3. Download the updated `google-services.json` if needed

Without Firebase configured, the app runs using **local auth** (email+password stored on device).

## API

AQI data is fetched from [Open-Meteo Air Quality API](https://open-meteo.com/en/docs/air-quality-api) (no API key required). Data is cached for 30 minutes per REQ-6.2.

## License

Proprietary - Vayu Aarambh Innovations Pvt. Ltd.
