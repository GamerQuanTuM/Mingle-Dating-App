from sqlalchemy import VARCHAR, TEXT, Column, DateTime, ARRAY, ForeignKey, func
from sqlalchemy.orm import relationship
from models.base import Base


class Asset(Base):
    __tablename__ = 'assets'

    id = Column(TEXT, primary_key=True)
    profile_picture = Column(VARCHAR(255), nullable=True)
    image_list = Column(ARRAY(TEXT), nullable=True)
    passion_list = Column(ARRAY(TEXT), nullable=True)
    created_at = Column(DateTime, default=func.now(), nullable=True)
    updated_at = Column(DateTime, default=func.now(),
                        onupdate=func.now(), nullable=True)
    user_id = Column(TEXT, ForeignKey("users.id"))

    # Use string for late binding
    user = relationship('User', back_populates='assets')

    def __repr__(self):
        return (f"<Asset(id={self.id}, profile_picture={self.profile_picture}, "
                f"created_at={self.created_at}, updated_at={self.updated_at})>")
