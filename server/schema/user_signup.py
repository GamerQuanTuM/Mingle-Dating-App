from pydantic import BaseModel

class UserSignup(BaseModel):
    name: str
    phone: str
    gender:str
    dob:str