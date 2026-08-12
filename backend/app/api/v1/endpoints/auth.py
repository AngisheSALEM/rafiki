import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import OwnerModel
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_jwt_token
from app.schemas.auth import OwnerRegisterSchema, OwnerLoginSchema, TokenResponseSchema, RefreshTokenRequestSchema

router = APIRouter()

@router.post("/register", response_model=TokenResponseSchema)
def register_owner(payload: OwnerRegisterSchema, db: Session = Depends(get_db)):
    """Registers a new Parent account in the database and returns JWT Access & Refresh Tokens with linked Robot ID."""
    existing_user = db.query(OwnerModel).filter(OwnerModel.email == payload.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Un compte parent existe deja avec cet email."
        )

    robot_id = f"RAFIKI-{uuid.uuid4().hex[:6].upper()}"
    new_owner = OwnerModel(
        full_name=payload.full_name,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        robot_id=robot_id
    )
    db.add(new_owner)
    db.commit()
    db.refresh(new_owner)

    token_payload = {"sub": str(new_owner.id), "email": new_owner.email, "name": new_owner.full_name, "robot_id": new_owner.robot_id}
    access_token = create_access_token(data=token_payload)
    refresh_token = create_refresh_token(data=token_payload)

    return TokenResponseSchema(
        access_token=access_token,
        refresh_token=refresh_token,
        owner_name=new_owner.full_name,
        owner_email=new_owner.email,
        robot_id=new_owner.robot_id
    )

@router.post("/login", response_model=TokenResponseSchema)
def login_owner(payload: OwnerLoginSchema, db: Session = Depends(get_db)):
    """Authenticates a Parent and returns fresh JWT Access & Refresh Tokens with linked Robot ID."""
    owner = db.query(OwnerModel).filter(OwnerModel.email == payload.email).first()
    if not owner or not verify_password(payload.password, owner.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect."
        )

    if not owner.robot_id:
        owner.robot_id = f"RAFIKI-{uuid.uuid4().hex[:6].upper()}"
        db.commit()

    token_payload = {"sub": str(owner.id), "email": owner.email, "name": owner.full_name, "robot_id": owner.robot_id}
    access_token = create_access_token(data=token_payload)
    refresh_token = create_refresh_token(data=token_payload)

    return TokenResponseSchema(
        access_token=access_token,
        refresh_token=refresh_token,
        owner_name=owner.full_name,
        owner_email=owner.email,
        robot_id=owner.robot_id
    )

@router.post("/refresh")
def refresh_token(payload: RefreshTokenRequestSchema, db: Session = Depends(get_db)):
    """Generates a new short-lived Access Token using a valid Refresh Token."""
    decoded = decode_jwt_token(payload.refresh_token)
    if not decoded or decoded.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de rafraichissement invalide ou expire."
        )

    owner_id = decoded.get("sub")
    owner = db.query(OwnerModel).filter(OwnerModel.id == int(owner_id)).first()
    if not owner:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Proprietaire non trouve."
        )

    token_payload = {"sub": str(owner.id), "email": owner.email, "name": owner.full_name}
    new_access_token = create_access_token(data=token_payload)

    return {
        "access_token": new_access_token,
        "token_type": "bearer"
    }
