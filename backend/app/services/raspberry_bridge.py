import json
import logging
from typing import Dict, Set
from fastapi import WebSocket, WebSocketDisconnect

logger = logging.getLogger("rafiki.raspberry_bridge")

class ConnectionManager:
    """
    Manages active WebSocket connections for:
    1. Rafiki Mobile Apps (The Mouth/Ears & Owner UI)
    2. Rafiki Raspberry Pi (The Physical Body)
    """
    def __init__(self):
        # Active app sockets (mobile clients)
        self.app_connections: Set[WebSocket] = set()
        # Active Raspberry Pi socket
        self.pi_connection: WebSocket | None = None
        # Robot Status Cache
        self.pi_status: Dict = {
            "connected": False,
            "battery_level": 95,
            "temperature_c": 38.5,
            "head_angle": 0,
            "expression": "happy",
            "last_seen": None
        }

    async def connect_app(self, websocket: WebSocket):
        await websocket.accept()
        self.app_connections.add(websocket)
        logger.info(f"Mobile app client connected. Total apps: {len(self.app_connections)}")
        # Send initial Pi status to connected mobile app
        await websocket.send_json({
            "type": "PI_STATUS_UPDATE",
            "data": self.pi_status
        })

    def disconnect_app(self, websocket: WebSocket):
        self.app_connections.remove(websocket)
        logger.info("Mobile app client disconnected.")

    async def connect_pi(self, websocket: WebSocket):
        await websocket.accept()
        self.pi_connection = websocket
        self.pi_status["connected"] = True
        logger.info("Raspberry Pi Robot connected successfully!")
        await self.broadcast_to_apps({
            "type": "PI_CONNECTION_CHANGED",
            "connected": True,
            "message": "Rafiki Robot Body is Online!"
        })

    def disconnect_pi(self):
        self.pi_connection = None
        self.pi_status["connected"] = False
        logger.info("Raspberry Pi Robot disconnected.")

    async def broadcast_to_apps(self, message: dict):
        """Send message from server/Pi to all connected mobile app instances."""
        to_remove = set()
        for connection in self.app_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting to app: {e}")
                to_remove.add(connection)
        for dead_conn in to_remove:
            self.app_connections.remove(dead_conn)

    async def send_to_pi(self, command: dict):
        """Send command (movement, expressiveness, sound trigger) from App/Server to Raspberry Pi."""
        if self.pi_connection and self.pi_status["connected"]:
            try:
                await self.pi_connection.send_json(command)
                return True
            except Exception as e:
                logger.error(f"Failed to send command to Pi: {e}")
                self.disconnect_pi()
                return False
        else:
            logger.warning("Attempted to send command to Pi, but Pi is not connected.")
            return False

    async def handle_pi_telemetry(self, data: dict):
        """Receive telemetry update from Raspberry Pi and forward to Mobile Apps."""
        self.pi_status.update(data.get("status", {}))
        self.pi_status["connected"] = True
        await self.broadcast_to_apps({
            "type": "PI_TELEMETRY",
            "data": self.pi_status
        })

raspberry_manager = ConnectionManager()
