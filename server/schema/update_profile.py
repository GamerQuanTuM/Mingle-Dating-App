from pydantic import BaseModel


class UpdateProfile(BaseModel):
    name: str = None,
    phone: str = None,
    dob: str = None,
