import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.db.database import Base

class OwnerModel(Base):
    __tablename__ = "owners"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    robot_id = Column(String, default="RAFIKI-ROBOT-001", nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    children = relationship("ChildModel", back_populates="owner", cascade="all, delete-orphan")
    conversations = relationship("ConversationModel", back_populates="owner", cascade="all, delete-orphan")


class ChildModel(Base):
    __tablename__ = "children"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    owner_id = Column(Integer, ForeignKey("owners.id"), nullable=False)
    name = Column(String, nullable=False)
    age = Column(Integer, nullable=False)
    preferred_topics = Column(String, default="Histoires, Contes, Jeux")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    owner = relationship("OwnerModel", back_populates="children")


class ConversationModel(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    owner_id = Column(Integer, ForeignKey("owners.id"), nullable=True)
    child_name = Column(String, default="Léo")
    title = Column(String, nullable=False)
    transcript = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Relationships
    owner = relationship("OwnerModel", back_populates="conversations")
