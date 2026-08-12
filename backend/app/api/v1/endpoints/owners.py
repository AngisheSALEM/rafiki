from typing import List
from fastapi import APIRouter, Depends, HTTPException, Header, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import OwnerModel, ChildModel
from app.core.security import decode_jwt_token
from app.schemas.auth import OwnerResponseSchema, ChildCreateSchema, ChildResponseSchema

router = APIRouter()

def get_current_owner(authorization: str = Header(...), db: Session = Depends(get_db)) -> OwnerModel:
    """Extracts and verifies current logged-in owner from Bearer JWT token in Authorization header."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header d'autorisation invalide. Format: Bearer <token>"
        )

    token = authorization.split(" ")[1]
    decoded = decode_jwt_token(token)
    if not decoded or decoded.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access Token invalide ou expire."
        )

    owner_id = decoded.get("sub")
    owner = db.query(OwnerModel).filter(OwnerModel.id == int(owner_id)).first()
    if not owner:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Compte parent non trouve."
        )

    return owner


@router.get("/me", response_model=OwnerResponseSchema)
def get_owner_profile(current_owner: OwnerModel = Depends(get_current_owner)):
    """Returns profile and children list for current authenticated Parent."""
    return current_owner


@router.get("/children", response_model=List[ChildResponseSchema])
def list_owner_children(current_owner: OwnerModel = Depends(get_current_owner)):
    """Fetches real persistent children profiles created by current authenticated Parent."""
    return current_owner.children


@router.post("/children", response_model=ChildResponseSchema)
def create_child_profile(
    payload: ChildCreateSchema,
    current_owner: OwnerModel = Depends(get_current_owner),
    db: Session = Depends(get_db)
):
    """Creates a new child profile in database attached to current Parent."""
    new_child = ChildModel(
        owner_id=current_owner.id,
        name=payload.name,
        age=payload.age,
        preferred_topics=payload.preferred_topics or "Contes, Histoires, Jeux"
    )
    db.add(new_child)
    db.commit()
    db.refresh(new_child)

    return new_child
