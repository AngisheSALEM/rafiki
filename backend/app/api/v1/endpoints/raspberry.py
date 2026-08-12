from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.services.raspberry_bridge import raspberry_manager

router = APIRouter()

class RobotCommandPayload(BaseModel):
    command: str  # e.g., "wave_hands", "tilt_head", "led_rainbow", "stop"
    speed: int = 50
    duration_ms: int = 1500

@router.get("/status")
async def get_pi_status():
    return raspberry_manager.pi_status

@router.post("/command")
async def send_command_to_pi(payload: RobotCommandPayload):
    success = await raspberry_manager.send_to_pi({
        "type": "ROBOT_COMMAND",
        "command": payload.command,
        "speed": payload.speed,
        "duration_ms": payload.duration_ms
    })
    if not success:
        return {
            "status": "warning",
            "message": "Command queued/logged, but Raspberry Pi is currently offline or unreachable."
        }
    return {"status": "success", "message": f"Command '{payload.command}' sent to Raspberry Pi!"}
