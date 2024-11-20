from sqlalchemy import Column, DateTime, ForeignKey, TEXT, String,Boolean
from sqlalchemy.sql import func
from models.base import Base
from sqlalchemy.orm import relationship

class Message(Base):
    __tablename__ = 'messages'

    id = Column(TEXT, primary_key=True)
    match_id = Column(TEXT, ForeignKey("matches.id"), nullable=False)
    sender_id = Column(TEXT, ForeignKey("users.id"), nullable=False)
    recipient_id = Column(TEXT, ForeignKey("users.id"), nullable=False)
    content = Column(TEXT, nullable=True)
    content_type = Column(String, nullable=False, default="text")
    file_url = Column(TEXT, nullable=True)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)
    seen = Column(Boolean, default=False, nullable=False)

    # Relationship to Match table
    match = relationship("Match", back_populates="messages")

    # Relationships to User table
    sender = relationship("User", foreign_keys=[sender_id], back_populates="sent_messages")
    recipient = relationship("User", foreign_keys=[recipient_id], back_populates="received_messages")

    def __repr__(self):
        return (f"<Message(id={self.id}, match_id={self.match_id}, sender_id={self.sender_id}, "
                f"recipient_id={self.recipient_id}, content_type={self.content_type}, "
                f"content={self.content[:20] if self.content else None}..., "
                f"file_url={self.file_url}, created_at={self.created_at})>")