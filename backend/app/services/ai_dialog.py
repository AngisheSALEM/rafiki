import random
import logging
import httpx
from typing import Dict, Any
from app.core.config import settings

logger = logging.getLogger("rafiki.ai_dialog")

class RafikiAIDialogService:
    """
    Connects to the Orchestrator LLM Agent (http://10.20.20.138:7860).
    Returns:
    - speech_text: What Rafiki says (sent to Mobile App TTS Mouth)
    - pi_action: Physical body movement (sent to Raspberry Pi via WebSocket)
    - emotion: Visual animation state for Flutter Avatar UI
    """
    
    RESPONSES = [
        {
            "triggers": ["bonjour", "salut", "hello", "coucou"],
            "speech": "Coucou ! Je suis Rafiki, ton meilleur ami robot ! Comment tu t'appelles aujourd'hui ?",
            "pi_action": {"movement": "wave_hands", "led_color": "green", "head": "tilt_right"},
            "emotion": "happy"
        },
        {
            "triggers": ["histoire", "raconte", "contes"],
            "speech": "Oh j'adore les histoires ! Une fois, un petit dragon bleu voulait apprendre à voler avec un cerf-volant...",
            "pi_action": {"movement": "nod_gently", "led_color": "blue", "head": "center"},
            "emotion": "storytelling"
        },
        {
            "triggers": ["chanson", "chante", "musique"],
            "speech": "La la la ! Rafiki aime chanter ! Une chanson douce pour s'amuser ensemble !",
            "pi_action": {"movement": "dance_bounce", "led_color": "rainbow", "head": "bob"},
            "emotion": "singing"
        },
        {
            "triggers": ["triste", "peur", "fatigué"],
            "speech": "Ne t'inquiète pas, Rafiki est là avec toi. Fais-moi un grand câlin imaginaire !",
            "pi_action": {"movement": "open_arms", "led_color": "warm_yellow", "head": "soft_tilt"},
            "emotion": "caring"
        }
    ]

    DEFAULT_RESPONSES = [
        "C'est très intéressant ! Peux-tu m'en dire un peu plus ?",
        "Wow, j'adore quand on discute tous les deux ! Tu es vraiment super génial !",
        "Dis-moi, quelle est ta couleur préférée aujourd'hui ?",
        "Aha ! Je suis si content d'être ton robot compagnon !"
    ]

    async def process_user_speech(self, text: str, child_name: str = "Ami") -> Dict[str, Any]:
        # 1. Try calling the LLM Orchestrator Agent at 10.20.20.138:7860
        try:
            async with httpx.AsyncClient(timeout=6.0) as client:
                response = await client.post(
                    f"{settings.LLM_ORCHESTRATOR_URL}/api/predict",
                    json={"text": text, "child_name": child_name}
                )
                if response.status_code == 200:
                    data = response.json()
                    return {
                        "speech_text": data.get("speech_text", data.get("response", "Je t'écoute !")),
                        "pi_action": data.get("pi_action", {"movement": "nod_gently", "led_color": "cyan"}),
                        "emotion": data.get("emotion", "happy")
                    }
        except Exception as e:
            logger.warning(f"LLM Orchestrator ({settings.LLM_ORCHESTRATOR_URL}) unavailable, using local rules fallback: {e}")

        # 2. Local fallback rules
        text_lower = text.lower()
        for item in self.RESPONSES:
            if any(trigger in text_lower for trigger in item["triggers"]):
                return {
                    "speech_text": item["speech"],
                    "pi_action": item["pi_action"],
                    "emotion": item["emotion"]
                }
        
        chosen_speech = random.choice(self.DEFAULT_RESPONSES)
        return {
            "speech_text": chosen_speech,
            "pi_action": {"movement": "blink_leds", "led_color": "cyan", "head": "center"},
            "emotion": "talking"
        }

ai_service = RafikiAIDialogService()
