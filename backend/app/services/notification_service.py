import logging
from typing import Dict, Any

import httpx

from ..core.database import get_db
from ..core.config import get_settings

logger = logging.getLogger(__name__)


class NotificationService:
    """Push notification service (OneSignal आधारित)"""

    def __init__(self):
        settings = get_settings()
        self.enabled = settings.push_notifications_enabled
        self.app_id = settings.onesignal_app_id
        self.api_key = settings.onesignal_rest_api_key
        self.endpoint = "https://onesignal.com/api/v1/notifications"

    # -------------------------
    # PUBLIC METHODS
    # -------------------------

    async def send_high_aqi_alert(self, user: Dict[str, Any], aqi_data: Dict[str, Any]) -> bool:
        payload = {
            "title": "High AQI Alert",
            "body": f"AQI {aqi_data.get('aqi')} detected at {aqi_data.get('location_name', 'your location')}",
            "data": {
                "type": "high_aqi",
                "aqi": aqi_data.get("aqi"),
            },
        }
        return await self._send(user, payload)

    async def send_daily_summary(self, user: Dict[str, Any], exposure: Dict[str, Any]) -> bool:
        payload = {
            "title": "Daily Exposure Summary",
            "body": f"Your exposure score today: {exposure.get('score', 0):.1f}",
            "data": {
                "type": "daily_summary",
                "score": exposure.get("score"),
            },
        }
        return await self._send(user, payload)

    async def send_test_notification(self, user: Dict[str, Any]) -> bool:
        payload = {
            "title": "Test Notification",
            "body": "This is a test notification from backend",
            "data": {"type": "test"},
        }
        return await self._send(user, payload)

    # -------------------------
    # CORE SEND LOGIC
    # -------------------------

    async def _send(self, user: Dict[str, Any], notification: Dict[str, Any]) -> bool:
        if not self.enabled:
            logger.info("Push disabled: %s", notification)
            return False

        user = await self._resolve_user(user)
        external_user_id = self._get_user_id(user)

        if not self.app_id or not self.api_key or not external_user_id:
            logger.warning("Missing config or user_id. Skipping notification.")
            return False

        payload = {
            "app_id": self.app_id,
            "include_external_user_ids": [external_user_id],
            "headings": {"en": notification.get("title", "Notification")},
            "contents": {"en": notification.get("body", "")},
            "data": notification.get("data", {}),
        }

        headers = {
            "Authorization": f"Basic {self.api_key}",
            "Content-Type": "application/json",
        }

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(self.endpoint, json=payload, headers=headers)

            result = response.json()

            if response.status_code >= 400 or "errors" in result:
                logger.error("OneSignal error: %s", result)
                return False

            logger.info("Notification sent to user_id=%s", external_user_id)
            return True

        except Exception as e:
            logger.exception("Notification failed: %s", e)
            return False

    # -------------------------
    # HELPERS
    # -------------------------

    async def _resolve_user(self, user: Dict[str, Any]) -> Dict[str, Any]:
        if not isinstance(user, dict):
            return {}

        user_id = user.get("id") or user.get("sub")

        if not user_id:
            return user

        try:
            profile = await get_db().get_user_profile(user_id)
            return profile or user
        except Exception as e:
            logger.warning("DB lookup failed: %s", e)
            return user

    def _get_user_id(self, user: Dict[str, Any]) -> str:
        return (
            user.get("id")
            or user.get("sub")
            or ""
        )