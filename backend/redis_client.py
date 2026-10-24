"""
Upstash Redis Client for Payano Backend
Manages real-time User and Driver actions, session caching, driver geolocation tracking, 
ride state management, action logging, and rate limiting using Upstash REST API.
"""

import os
import json
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
import httpx

class UpstashRedis:
    def __init__(self, url: Optional[str] = None, token: Optional[str] = None):
        self.url = (url or os.getenv("UPSTASH_REDIS_REST_URL", "")).rstrip('/')
        self.token = token or os.getenv("UPSTASH_REDIS_REST_TOKEN", "")
        self.headers = {"Authorization": f"Bearer {self.token}"} if self.token else {}
        self._is_connected = False

    @property
    def is_configured(self) -> bool:
        return bool(self.url and self.token)

    async def exec_cmd(self, *args) -> Any:
        """Executes a single Redis command via Upstash REST API."""
        if not self.is_configured:
            return None
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.post(self.url, headers=self.headers, json=list(args))
                if res.status_code == 200:
                    data = res.json()
                    return data.get("result")
                else:
                    print(f"[WARN] Upstash Redis error {res.status_code}: {res.text}")
                    return None
        except Exception as e:
            print(f"[WARN] Upstash Redis request failed: {e}")
            return None

    async def pipeline(self, commands: List[List[Any]]) -> List[Any]:
        """Executes multiple Redis commands in a pipeline."""
        if not self.is_configured or not commands:
            return []
        try:
            pipeline_url = f"{self.url}/pipeline"
            async with httpx.AsyncClient(timeout=5.0) as client:
                res = await client.post(pipeline_url, headers=self.headers, json=commands)
                if res.status_code == 200:
                    results = res.json()
                    return [r.get("result") for r in results]
                return []
        except Exception as e:
            print(f"[WARN] Upstash Redis pipeline failed: {e}")
            return []

    async def ping(self) -> bool:
        res = await self.exec_cmd("PING")
        self._is_connected = (res == "PONG")
        return self._is_connected

    # ─── DRIVER LOCATION & GEOLOCATION ────────────────────────────────────

    async def set_driver_location(
        self, driver_id: str, lat: float, lng: float, heading: float = 0.0, speed: float = 0.0, ttl: int = 3600
    ) -> bool:
        """Stores real-time driver coordinates in Redis hash & GeoSpatial index."""
        now_iso = datetime.now(timezone.utc).isoformat()
        loc_key = f"driver:location:{driver_id}"
        loc_data = {
            "latitude": str(lat),
            "longitude": str(lng),
            "heading": str(heading),
            "speed": str(speed),
            "updatedAt": now_iso,
        }
        
        cmds = [
            ["HSET", loc_key] + [item for pair in loc_data.items() for item in pair],
            ["EXPIRE", loc_key, ttl],
            ["GEOADD", "drivers:geo", lng, lat, driver_id],
        ]
        results = await self.pipeline(cmds)
        return bool(results)

    async def get_driver_location(self, driver_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves real-time driver location from Redis."""
        loc_key = f"driver:location:{driver_id}"
        res = await self.exec_cmd("HGETALL", loc_key)
        if not res:
            return None
        # Convert list of key-value pairs or dict response
        if isinstance(res, list):
            loc_dict = {res[i]: res[i+1] for i in range(0, len(res), 2)}
        elif isinstance(res, dict):
            loc_dict = res
        else:
            return None
        
        try:
            return {
                "latitude": float(loc_dict.get("latitude", 0.0)),
                "longitude": float(loc_dict.get("longitude", 0.0)),
                "heading": float(loc_dict.get("heading", 0.0)),
                "speed": float(loc_dict.get("speed", 0.0)),
                "updatedAt": loc_dict.get("updatedAt"),
            }
        except (ValueError, TypeError):
            return None

    async def get_all_driver_locations() -> Dict[str, Dict[str, Any]]:
        """Retrieves location of all online drivers."""
        pass # implemented in instance method below

    async def get_online_driver_locations(self) -> Dict[str, Dict[str, Any]]:
        driver_ids = await self.exec_cmd("SMEMBERS", "drivers:online")
        if not driver_ids:
            return {}
        locations = {}
        for driver_id in driver_ids:
            loc = await self.get_driver_location(driver_id)
            if loc:
                locations[driver_id] = loc
        return locations

    # ─── DRIVER ONLINE / OFFLINE STATUS ───────────────────────────────────

    async def set_driver_status(
        self, driver_id: str, is_online: bool, lat: Optional[float] = None, lng: Optional[float] = None
    ) -> bool:
        """Manages online driver set and status in Redis."""
        now_iso = datetime.now(timezone.utc).isoformat()
        status_key = f"driver:status:{driver_id}"
        
        cmds = []
        if is_online:
            cmds.append(["SADD", "drivers:online", driver_id])
        else:
            cmds.append(["SREM", "drivers:online", driver_id])

        status_data = {
            "isOnline": "1" if is_online else "0",
            "updatedAt": now_iso,
        }
        if lat is not None and lng is not None:
            status_data["latitude"] = str(lat)
            status_data["longitude"] = str(lng)
            
        cmds.append(["HSET", status_key] + [item for pair in status_data.items() for item in pair])
        cmds.append(["EXPIRE", status_key, 86400])

        if lat is not None and lng is not None:
            cmds.append(["GEOADD", "drivers:geo", lng, lat, driver_id])

        results = await self.pipeline(cmds)
        return bool(results)

    async def get_online_drivers(self) -> List[str]:
        res = await self.exec_cmd("SMEMBERS", "drivers:online")
        return res if isinstance(res, list) else []

    # ─── USER & DRIVER SESSION / PROFILE CACHING ──────────────────────────

    async def cache_user(self, user_id: str, user_data: dict, ttl: int = 86400) -> bool:
        """Caches user profile data in Redis."""
        key = f"user:profile:{user_id}"
        res = await self.exec_cmd("SET", key, json.dumps(user_data), "EX", ttl)
        return res == "OK"

    async def get_cached_user(self, user_id: str) -> Optional[dict]:
        """Fetches cached user profile data."""
        key = f"user:profile:{user_id}"
        res = await self.exec_cmd("GET", key)
        if res and isinstance(res, str):
            try:
                return json.loads(res)
            except Exception:
                return None
        return None

    async def cache_driver(self, driver_id: str, driver_data: dict, ttl: int = 86400) -> bool:
        """Caches driver profile data in Redis."""
        key = f"driver:profile:{driver_id}"
        res = await self.exec_cmd("SET", key, json.dumps(driver_data), "EX", ttl)
        return res == "OK"

    async def get_cached_driver(self, driver_id: str) -> Optional[dict]:
        """Fetches cached driver profile data."""
        key = f"driver:profile:{driver_id}"
        res = await self.exec_cmd("GET", key)
        if res and isinstance(res, str):
            try:
                return json.loads(res)
            except Exception:
                return None
        return None

    # ─── RIDE STATE CACHING ────────────────────────────────────────────────

    async def cache_ride(self, ride_id: str, ride_data: dict, ttl: int = 7200) -> bool:
        """Caches active ride state for fast access during trips."""
        key = f"ride:active:{ride_id}"
        passenger_id = ride_data.get("passengerId")
        driver_id = ride_data.get("driverId")

        cmds = [
            ["SET", key, json.dumps(ride_data), "EX", ttl]
        ]
        if passenger_id:
            cmds.append(["SET", f"user:active_ride:{passenger_id}", ride_id, "EX", ttl])
        if driver_id:
            cmds.append(["SET", f"driver:active_ride:{driver_id}", ride_id, "EX", ttl])

        results = await self.pipeline(cmds)
        return bool(results)

    async def get_cached_ride(self, ride_id: str) -> Optional[dict]:
        """Retrieves cached ride state."""
        key = f"ride:active:{ride_id}"
        res = await self.exec_cmd("GET", key)
        if res and isinstance(res, str):
            try:
                return json.loads(res)
            except Exception:
                return None
        return None

    async def clear_active_ride(self, ride_id: str, passenger_id: Optional[str] = None, driver_id: Optional[str] = None) -> bool:
        """Clears active ride state mappings upon completion or cancellation."""
        cmds = [["DEL", f"ride:active:{ride_id}"]]
        if passenger_id:
            cmds.append(["DEL", f"user:active_ride:{passenger_id}"])
        if driver_id:
            cmds.append(["DEL", f"driver:active_ride:{driver_id}"])
        results = await self.pipeline(cmds)
        return bool(results)

    # ─── USER & DRIVER ACTIVITY AUDIT LOGGING ─────────────────────────────

    async def log_action(
        self, entity_type: str, entity_id: str, action_type: str, details: Optional[dict] = None, max_logs: int = 50
    ) -> bool:
        """Logs a user or driver action to a Redis list for audit trails and recent activity."""
        key = f"activity:{entity_type}:{entity_id}"
        log_entry = {
            "entityType": entity_type,
            "entityId": entity_id,
            "action": action_type,
            "details": details or {},
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        cmds = [
            ["LPUSH", key, json.dumps(log_entry)],
            ["LTRIM", key, 0, max_logs - 1],
            ["EXPIRE", key, 604800] # Keep activity logs for 7 days
        ]
        results = await self.pipeline(cmds)
        return bool(results)

    async def get_activity_logs(self, entity_type: str, entity_id: str, count: int = 20) -> List[dict]:
        """Fetches recent activity logs for a user or driver."""
        key = f"activity:{entity_type}:{entity_id}"
        res = await self.exec_cmd("LRANGE", key, 0, count - 1)
        if not res or not isinstance(res, list):
            return []
        logs = []
        for item in res:
            try:
                logs.append(json.loads(item))
            except Exception:
                pass
        return logs

    # ─── RATE LIMITING ────────────────────────────────────────────────────

    async def check_rate_limit(self, key: str, limit: int = 60, window_seconds: int = 60) -> bool:
        """
        Rate limiting helper. Returns True if action is allowed, False if rate limit exceeded.
        """
        rl_key = f"rate:{key}"
        cmds = [
            ["INCR", rl_key],
            ["EXPIRE", rl_key, window_seconds]
        ]
        results = await self.pipeline(cmds)
        if results and isinstance(results[0], int):
            count = results[0]
            return count <= limit
        return True

# Singleton instance
redis_client = UpstashRedis()
