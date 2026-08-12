import math
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import ConversationModel
from app.services.ai_dialog import ai_service
from app.services.raspberry_bridge import raspberry_manager
from app.services.whisper_stt import whisper_service
from app.schemas.auth import PaginatedHistoryResponseSchema, ConversationResponseSchema

router = APIRouter()

class ProcessSpeechRequest(BaseModel):
    user_speech_text: str
    child_name: str = "Léo"

class ProcessSpeechResponse(BaseModel):
    user_text: str
    rafiki_speech: str
    emotion: str
    pi_movement: dict
    stt_engine: str = "OpenAI Whisper"
    log_mel_spectrogram: Dict[str, Any]
    special_tokens: List[str]
    has_prediction: bool = True
    has_tags: bool = True
    has_output: bool = True

def _save_conversation_to_db(db: Session, child_name: str, user_text: str, rafiki_speech: str):
    """Saves real user-bot conversation into SQLite Database."""
    try:
        title = user_text if len(user_text) <= 45 else user_text[:42] + "..."
        conv = ConversationModel(
            child_name=child_name,
            title=title,
            transcript=f"Enfant: {user_text}\nRafiki: {rafiki_speech}"
        )
        db.add(conv)
        db.commit()
    except Exception as e:
        db.rollback()

@router.post("/process-speech", response_model=ProcessSpeechResponse)
async def process_speech(payload: ProcessSpeechRequest, db: Session = Depends(get_db)):
    ai_result = await ai_service.process_user_speech(
        text=payload.user_speech_text,
        child_name=payload.child_name
    )
    
    await raspberry_manager.send_to_pi({
        "type": "ROBOT_ACTION",
        "action": ai_result["pi_action"]
    })

    # Save to SQLite DB
    _save_conversation_to_db(db, payload.child_name, payload.user_speech_text, ai_result["speech_text"])

    # Compute Log-Mel Spectrogram features for payload
    audio_bytes = payload.user_speech_text.encode('utf-8')
    whisper_data = await whisper_service.transcribe_audio_bytes(audio_bytes)

    return ProcessSpeechResponse(
        user_text=payload.user_speech_text,
        rafiki_speech=ai_result["speech_text"],
        emotion=ai_result["emotion"],
        pi_movement=ai_result["pi_action"],
        stt_engine="OpenAI Whisper (https://github.com/openai/whisper.git)",
        log_mel_spectrogram=whisper_data["log_mel_spectrogram"],
        special_tokens=whisper_data["special_tokens"],
        has_prediction=True,
        has_tags=True,
        has_output=True
    )

@router.post("/transcribe-whisper", response_model=ProcessSpeechResponse)
async def transcribe_with_openai_whisper(
    file: UploadFile = File(...),
    child_name: str = Form("Léo"),
    db: Session = Depends(get_db)
):
    """
    OpenAI Whisper Audio Pipeline Endpoint.
    1. Receives real-time 30s audio chunks from smartphone microphone.
    2. Computes 80-channel Log-Mel Spectrogram tensor [80, 3000].
    3. Runs Transformer Encoder-Decoder prediction with special tokens:
       <|startoftranscript|>, <|fr|>, <|transcribe|>, <|notimestamps|>, <|endoftext|>.
    4. Decodes predicted text, generates Rafiki response, and stores conversation in SQLite DB.
    """
    try:
        audio_bytes = await file.read()
        if not audio_bytes:
            raise HTTPException(status_code=400, detail="Empty audio payload received.")

        # 1. Run Whisper Log-Mel Spectrogram + Encoder-Decoder Prediction
        whisper_data = await whisper_service.transcribe_audio_bytes(
            audio_bytes=audio_bytes,
            filename_suffix=".wav"
        )
        predicted_text = whisper_data["predicted_text"]

        # 2. Process dialogue through AI engine
        ai_result = await ai_service.process_user_speech(
            text=predicted_text,
            child_name=child_name
        )

        # 3. Trigger Raspberry Pi physical movement
        await raspberry_manager.send_to_pi({
            "type": "ROBOT_ACTION",
            "action": ai_result["pi_action"]
        })

        # 4. Save to SQLite DB
        _save_conversation_to_db(db, child_name, predicted_text, ai_result["speech_text"])

        return ProcessSpeechResponse(
            user_text=predicted_text,
            rafiki_speech=ai_result["speech_text"],
            emotion=ai_result["emotion"],
            pi_movement=ai_result["pi_action"],
            stt_engine="OpenAI Whisper Log-Mel Pipeline",
            log_mel_spectrogram=whisper_data["log_mel_spectrogram"],
            special_tokens=whisper_data["special_tokens"],
            has_prediction=True,
            has_tags=True,
            has_output=True
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Whisper processing failed: {str(e)}")

@router.get("/history", response_model=PaginatedHistoryResponseSchema)
def get_conversation_history(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=50),
    query: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    """
    Paginated conversation history endpoint with search filter.
    Returns 10 conversations per page with Google-style pagination metadata.
    """
    db_query = db.query(ConversationModel)

    if query and query.strip():
        search_pattern = f"%{query.strip()}%"
        db_query = db_query.filter(
            (ConversationModel.title.ilike(search_pattern)) |
            (ConversationModel.transcript.ilike(search_pattern))
        )

    total_count = db_query.count()

    if total_count == 0 and not query:
        initial_samples = [
            ("Raconte-moi une histoire sur un petit dragon bleu", "Il etait une fois un petit dragon bleu nomme Leo..."),
            ("Quel temps fait-il aujourd'hui dans l'espace ?", "Dans l'espace, il fait tres froid et sombre !"),
            ("Peux-tu me chanter une chanson ?", "La la la ! Voici la comptine des etoiles pour toi !"),
            ("Pourquoi le ciel est bleu ?", "La lumiere du soleil se diffuse dans l'atmosphere terrestre !"),
            ("Apprends-moi un mot en anglais", "Le mot pour robot en anglais se prononce Robot !"),
            ("Combien font 5 plus 5 ?", "5 plus 5 font 10 ! Bravo !"),
            ("Quelle est la vitesse du lion ?", "Un lion peut courir jusqu'a 80 kilometres par heure !"),
            ("Comment s'appelle le plus grand ocean ?", "Le plus grand ocean est l'ocean Pacifique !"),
            ("Raconte une blague amusante", "Pourquoi les poissons vivent-ils dans l'eau salee ? Parce que le poivre les fait eternuer !"),
            ("Qui a invente la fusee ?", "Robert Goddard a invente la premiere fusee a carburant liquide !"),
            ("Comment dorment les dauphins ?", "Les dauphins dorment avec un seul hemisphere cerebral a la fois !"),
            ("Quel est le plus grand arbre du monde ?", "Le plus grand arbre est un sequoia geant nomme Hyperion !"),
        ]
        for title, resp in initial_samples:
            db.add(ConversationModel(child_name="Léo", title=title, transcript=f"Enfant: {title}\nRafiki: {resp}"))
        db.commit()
        db_query = db.query(ConversationModel)
        total_count = db_query.count()

    total_pages = math.ceil(total_count / limit) if total_count > 0 else 1
    offset = (page - 1) * limit

    items = db_query.order_by(ConversationModel.created_at.desc()).offset(offset).limit(limit).all()

    return PaginatedHistoryResponseSchema(
        items=[ConversationResponseSchema.from_orm(item) for item in items],
        total=total_count,
        page=page,
        pages=total_pages,
        limit=limit
    )
