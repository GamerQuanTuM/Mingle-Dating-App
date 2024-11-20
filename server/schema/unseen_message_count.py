from pydantic import BaseModel

class UnseenMessageCount(BaseModel):
    recipient_id:str