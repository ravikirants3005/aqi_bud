"""
Response and payload normalization helpers for AQI Buddy Backend.
"""

from typing import Any, Dict, List, Optional


def _as_list(value: Any) -> List[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def normalize_user_profile_payload(payload: Dict[str, Any], user_id: Optional[str] = None) -> Dict[str, Any]:
    notification_prefs = payload.get("notification_prefs") or payload.get("notificationPrefs") or {}
    saved_locations = payload.get("saved_locations") or payload.get("savedLocations") or []

    normalized_locations = []
    for location in _as_list(saved_locations):
        if not isinstance(location, dict):
            continue
        normalized_locations.append(normalize_saved_location_payload(location, user_id=user_id))

    return {
        "id": user_id or payload.get("id"),
        "email": payload.get("email"),
        "phone": payload.get("phone"),
        "display_name": payload.get("display_name") or payload.get("displayName") or payload.get("display_name"),
        "health_sensitivity": payload.get("health_sensitivity") or payload.get("healthSensitivity") or "normal",
        "age_group": payload.get("age_group") or payload.get("ageGroup"),
        "push_token": payload.get("push_token") or payload.get("pushToken"),
        "notification_prefs": notification_prefs,
        "saved_locations": normalized_locations,
    }


def serialize_saved_location(row: Dict[str, Any]) -> Dict[str, Any]:
    if isinstance(row, list):
        row = row[0] if row else {}
    return {
        "id": row.get("id"),
        "userId": row.get("user_id"),
        "name": row.get("name"),
        "lat": row.get("lat"),
        "lng": row.get("lng"),
        "lastAqi": row.get("last_aqi", row.get("lastAqi")),
        "lastUpdated": row.get("last_updated", row.get("lastUpdated")),
        "createdAt": row.get("created_at", row.get("createdAt")),
    }


def normalize_saved_location_payload(payload: Dict[str, Any], user_id: Optional[str] = None) -> Dict[str, Any]:
    return {
        "id": payload.get("id"),
        "user_id": user_id or payload.get("user_id") or payload.get("userId"),
        "name": payload.get("name"),
        "lat": payload.get("lat"),
        "lng": payload.get("lng"),
        "last_aqi": payload.get("last_aqi", payload.get("lastAqi")),
        "last_updated": payload.get("last_updated", payload.get("lastUpdated")),
    }


def serialize_exposure_record(row: Dict[str, Any]) -> Dict[str, Any]:
    if isinstance(row, list):
        row = row[0] if row else {}
    return {
        "id": row.get("id"),
        "userId": row.get("user_id"),
        "date": row.get("date"),
        "score": row.get("score"),
        "maxAqi": row.get("max_aqi", row.get("maxAqi")),
        "outdoorMinutes": row.get("outdoor_minutes", row.get("outdoorMinutes")),
        "locationExposures": row.get("location_exposures", row.get("locationExposures", [])),
        "createdAt": row.get("created_at", row.get("createdAt")),
    }


def normalize_exposure_payload(payload: Dict[str, Any], user_id: Optional[str] = None) -> Dict[str, Any]:
    return {
        "id": payload.get("id"),
        "user_id": user_id or payload.get("user_id") or payload.get("userId"),
        "date": payload.get("date") or payload.get("record_date") or payload.get("recordDate"),
        "score": payload.get("score", payload.get("total_exposure_score", payload.get("totalExposureScore"))),
        "max_aqi": payload.get("max_aqi", payload.get("maxAqi")),
        "outdoor_minutes": payload.get("outdoor_minutes", payload.get("outdoorMinutes")),
        "location_exposures": payload.get("location_exposures", payload.get("locationExposures", [])),
    }


def serialize_user_profile(row: Dict[str, Any]) -> Dict[str, Any]:
    if isinstance(row, list):
        row = row[0] if row else {}
    return {
        "id": row.get("id"),
        "email": row.get("email"),
        "phone": row.get("phone"),
        "displayName": row.get("display_name", row.get("displayName")),
        "healthSensitivity": row.get("health_sensitivity", row.get("healthSensitivity", "normal")),
        "ageGroup": row.get("age_group", row.get("ageGroup")),
        "pushToken": row.get("push_token", row.get("pushToken")),
        "notificationPrefs": row.get("notification_prefs", row.get("notificationPrefs", {})),
        "savedLocations": [serialize_saved_location(loc) for loc in row.get("saved_locations", row.get("savedLocations", []))],
        "createdAt": row.get("created_at", row.get("createdAt")),
        "updatedAt": row.get("updated_at", row.get("updatedAt")),
    }


def serialize_aqi_data(data: Dict[str, Any]) -> Dict[str, Any]:
    if isinstance(data, list):
        data = data[0] if data else {}
    return {
        "aqi": data.get("aqi"),
        "lat": data.get("lat"),
        "lng": data.get("lng"),
        "pm25": data.get("pm25"),
        "pm10": data.get("pm10"),
        "o3": data.get("o3"),
        "no2": data.get("no2"),
        "so2": data.get("so2"),
        "co": data.get("co"),
        "locationName": data.get("location_name", data.get("locationName")),
        "timestamp": data.get("timestamp"),
        "source": data.get("data_source", data.get("source", "openmeteo")),
    }