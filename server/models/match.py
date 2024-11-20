import uuid
from sqlalchemy import Column, DateTime, ForeignKey, Enum, TEXT
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from models.base import Base
import enum


class MatchStatus(enum.Enum):
    ACTIVE = "ACTIVE"
    UNMATCHED = "UNMATCHED"
    REJECTED = "REJECTED"


class Match(Base):
    __tablename__ = 'matches'

    id = Column(TEXT, primary_key=True, default=lambda: str(uuid.uuid4()))
    user1_id = Column(TEXT, ForeignKey("users.id"), nullable=False)
    user2_id = Column(TEXT, ForeignKey("users.id"), nullable=False)
    status = Column(Enum(MatchStatus),
                    default=MatchStatus.UNMATCHED, nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(),
                        onupdate=func.now(), nullable=False)

    # Relationships to User table
    user1 = relationship("User", foreign_keys=[
                         user1_id], back_populates="matches_as_user1")
    user2 = relationship("User", foreign_keys=[
                         user2_id], back_populates="matches_as_user2")

    # Relationship to Message table
    messages = relationship(
        "Message", back_populates="match", cascade="all, delete-orphan")

    def __repr__(self):
        return (f"<Match(id={self.id}, user1_id={self.user1_id}, user2_id={self.user2_id}, "
                f"status={self.status}, created_at={self.created_at}, updated_at={self.updated_at})>")
