from fastapi import Header, HTTPException

import jwt
from dotenv import load_dotenv
import os

load_dotenv()
jwt_secret = os.getenv('JWT_SECRET')


def auth_middleware(x_auth_token=Header()):
    try:
        if not x_auth_token:
            raise HTTPException(401, "Access denied!! No auth token found.")

        isVerified = jwt.decode(x_auth_token, jwt_secret, ['HS256'])

        if not isVerified:
            raise HTTPException(
                401, "Access denied!! Token verification failed.")

        uid = isVerified.get("id")
        return {"uid": uid, "token": x_auth_token}
    except jwt.PyJWTError as e:
        raise HTTPException(401, "Access denied!! Auth token not valid.")
