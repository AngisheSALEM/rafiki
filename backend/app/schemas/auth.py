from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class OwnerRegisterSchema(BaseModel):
    full_name: str
    email: str
    password: str

class OwnerLoginSchema(BaseModel):
    email: str
    password: str

class TokenResponseSchema(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    owner_name: str
    owner_email: str
    robot_id: str = "RAFIKI-ROBOT-001"

class RefreshTokenRequestSchema(BaseModel):
    refresh_token: str

class ChildCreateSchema(BaseModel):
    name: str
    age: int
    preferred_topics: Optional[str] = "Contes, Histoires, Jeux"

class ChildResponseSchema(BaseModel):
    id: int
    owner_id: int
    name: str
    age: int
    preferred_topics: str

    class Config:
        from_attributes = True

class OwnerResponseSchema(BaseModel):
    id: int
    full_name: str
    email: str
    robot_id: str = "RAFIKI-ROBOT-001"
    children: List[ChildResponseSchema] = []

    class Config:
        from_attributes = True

class ConversationResponseSchema(BaseModel):
    id: int
    child_name: str
    title: str
    transcript: str
    created_at: datetime

    class Config:
        from_attributes = True

class PaginatedHistoryResponseSchema(BaseModel):
    items: List[ConversationResponseSchema]
    total: int
    page: int
    pages: int
    limit: int
