from pydantic_settings import BaseSettings
from typing import List, Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "Rafiki Robot Core Backend"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Security
    SECRET_KEY: str = "rafiki_secret_key_change_in_production_39824792374982374"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # CORS
    ALLOWED_ORIGINS: List[str] = ["*"]
    
    # Raspberry Pi Default Config
    DEFAULT_PI_PORT: int = 8765
    PI_SECRET_TOKEN: str = "rafiki_pi_secure_token_12345"

    # LLM Orchestrator Agent (Remote / Local Server)
    LLM_ORCHESTRATOR_URL: str = "http://10.20.20.138:7860"
    PORT: int = 8000

    class Config:
        case_sensitive = True

settings = Settings()
