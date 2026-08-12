from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
import json
import logging

from app.core.config import settings
from app.api.v1.endpoints import auth, owners, raspberry, audio
from app.services.raspberry_bridge import raspberry_manager
from app.db.database import init_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rafiki.main")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Rafiki Robot Companion Backend - Managing AI Dialogue, STT/TTS Sync, Raspberry Pi hardware, and Owner Dashboard."
)

# Initialize Database tables on startup
@app.on_event("startup")
def on_startup():
    logger.info("Initializing SQLite Database tables (owners, children)...")
    init_db()

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router, prefix=f"{settings.API_V1_STR}/auth", tags=["Auth & Owners"])
app.include_router(owners.router, prefix=f"{settings.API_V1_STR}/owners", tags=["Owner Management"])
app.include_router(raspberry.router, prefix=f"{settings.API_V1_STR}/raspberry", tags=["Raspberry Pi Hardware"])
app.include_router(audio.router, prefix=f"{settings.API_V1_STR}/audio", tags=["Audio & AI Dialog"])

@app.get("/")
async def root():
    return {
        "status": "online",
        "app_name": "Rafiki Robot Companion API",
        "version": settings.VERSION,
        "pi_connected": raspberry_manager.pi_status["connected"]
    }

# Real-time WebSocket Endpoint for Mobile Applications (Flutter)
@app.websocket("/ws/mobile")
async def websocket_mobile_endpoint(websocket: WebSocket):
    await raspberry_manager.connect_app(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            logger.info(f"Received message from Mobile App: {message}")
            
            # Forward user commands to Pi if requested
            if message.get("type") == "PI_COMMAND":
                await raspberry_manager.send_to_pi(message.get("payload", {}))
                
    except WebSocketDisconnect:
        raspberry_manager.disconnect_app(websocket)

# Real-time WebSocket Endpoint for Rafiki's Raspberry Pi (Robot Hardware Body)
@app.websocket("/ws/raspberry")
async def websocket_raspberry_endpoint(websocket: WebSocket):
    await raspberry_manager.connect_pi(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle status / sensor update from Pi
            if message.get("type") == "PI_TELEMETRY":
                await raspberry_manager.handle_pi_telemetry(message)
                
    except WebSocketDisconnect:
        raspberry_manager.disconnect_pi()

if __name__ == "__main__":
    import uvicorn
    import os
    port = int(os.getenv("PORT", settings.PORT))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)
