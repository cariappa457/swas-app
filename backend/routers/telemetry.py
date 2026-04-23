from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict
import json
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

# Connection manager to broadcast and hold live socket connections
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        logger.info(f"User {user_id} connected to live telemetry.")

    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            logger.info(f"User {user_id} disconnected.")

    async def broadcast_location(self, user_id: str, lat: float, lng: float):
        # In a real system, you'd broadcast to the specific user's contacts.
        # For prototype, we echo or broadcast broadly.
        message = json.dumps({
            "user_id": user_id,
            "lat": lat,
            "lng": lng,
            "type": "location_update"
        })
        for uid, connection in self.active_connections.items():
            try:
                await connection.send_text(message)
            except Exception as e:
                logger.error(f"Error broadcasting to {uid}: {str(e)}")

manager = ConnectionManager()

@router.websocket("/ws/telemetry/{user_id}")
async def websocket_telemetry(websocket: WebSocket, user_id: str):
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_text()
            try:
                payload = json.loads(data)
                # Client sends: {"lat": 12.0, "lng": 77.0}
                if "lat" in payload and "lng" in payload:
                    await manager.broadcast_location(user_id, payload["lat"], payload["lng"])
            except json.JSONDecodeError:
                pass
    except WebSocketDisconnect:
        manager.disconnect(user_id)
