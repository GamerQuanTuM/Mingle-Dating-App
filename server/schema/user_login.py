from pydantic import BaseModel

class UserLogin(BaseModel):
    phone: str
    country_code:str
    otp:str