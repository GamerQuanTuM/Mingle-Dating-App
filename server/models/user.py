import enum
from sqlalchemy import VARCHAR, TEXT, Enum, Column, DateTime, INTEGER, func, extract
from sqlalchemy.orm import relationship
from models.base import Base
from datetime import datetime
from sqlalchemy.ext.hybrid import hybrid_property

class Gender(enum.Enum):
    MALE = "MALE"
    FEMALE = "FEMALE"

class User(Base):
    __tablename__ = 'users'

    id = Column(TEXT, primary_key=True)
    name = Column(VARCHAR(100), nullable=False)
    phone = Column(VARCHAR(15), nullable=False)
    dob = Column(DateTime, nullable=False)
    gender = Column(Enum(Gender), nullable=False)
    created_at = Column(DateTime, default=func.now(), nullable=False)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now(), nullable=False)

    # Use string for late binding
    assets = relationship('Asset', back_populates='user')

    # Relationships to Match table
    matches_as_user1 = relationship('Match', foreign_keys='Match.user1_id', back_populates='user1')
    matches_as_user2 = relationship('Match', foreign_keys='Match.user2_id', back_populates='user2')

    # Relationship to Message table
    sent_messages = relationship('Message', foreign_keys='Message.sender_id', back_populates='sender')
    received_messages = relationship('Message', foreign_keys='Message.recipient_id', back_populates='recipient')

    @hybrid_property
    def age(self):
        today = datetime.now()
        return today.year - self.dob.year - ((today.month, today.day) < (self.dob.month, self.dob.day))

    @age.expression
    def age(cls):
        # Calculate age approximately by year only in SQL
        return extract('year', func.now()) - extract('year', cls.dob)

    def __repr__(self):
        return (f"<User(id={self.id}, name={self.name}, phone={self.phone}, "
                f"dob={self.dob}, age={self.age}, gender={self.gender})>")