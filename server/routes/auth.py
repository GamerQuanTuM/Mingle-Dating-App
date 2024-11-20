from fastapi import APIRouter, HTTPException, Depends
import jwt
from sqlalchemy.orm import Session
import uuid
from dotenv import load_dotenv
import os
from sqlalchemy.exc import SQLAlchemyError

from config.database import get_db
from schema.user_signup import UserSignup
from schema.user_login import UserLogin
from schema.phone_request import PhoneRequest
from models.user import User
from config.redis_client import redis_client
from config.twilio_client import twilio_client, twilio_phone_number
from middleware.auth_middleware import auth_middleware

load_dotenv()

jwt_secret = os.getenv('JWT_SECRET')
router = APIRouter(tags=["Auth"])

# Route to create a new user (signup)


@router.post("/signup", status_code=201)
def user_create(user: UserSignup, db: Session = Depends(get_db)):
    try:
        existing_user = db.query(User).filter(User.phone == user.phone).first()
        if existing_user:
            raise HTTPException(
                status_code=409, detail="User with this phone number already exists")

        new_user = User(
            id=str(uuid.uuid4()),
            name=user.name,
            phone=user.phone,
            dob=user.dob,
            gender=user.gender,
        )

        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        return {
            "message": "Success",
            "user": {
                "id": new_user.id,
                "name": new_user.name,
                "phone": new_user.phone,
                "gender": new_user.gender,
                "dob": new_user.dob,
                "age": new_user.age,
                "created_at": new_user.created_at,
                "updated_at": new_user.updated_at,
            }
        }
    except SQLAlchemyError as e:
        db.rollback()  # Rollback in case of any database error
        raise HTTPException(
            status_code=500, detail="Database error occurred while processing match request.")
    except HTTPException as e:
        raise e  # Rethrow HTTP exceptions to avoid them being caught as 500 errors
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred.")


# Route to generate and send OTP to the user using Redis for storage
@router.post("/generate-otp", status_code=200)
def generate_otp(phone_request: PhoneRequest, db: Session = Depends(get_db)):
    try:
        phone = phone_request.phone
        country_code = phone_request.country_code

        print(phone_request)
        existing_user = db.query(User).filter(User.phone == phone).first()
        if not existing_user:
            raise HTTPException(status_code=404, detail="User not found")

        # otp = str(random.randint(1000, 9999))
        otp = 9999
        redis_client.setex(phone, 300, otp)

        phone_number = f"{country_code}{phone}"

        # Send OTP via Twilio SMS
        # message = twilio_client.messages.create(
        #     body=f"Your OTP code is {otp}.",
        #     from_=twilio_phone_number,
        #     to=phone_number
        # )

        return {
            "message": "OTP sent successfully",
            # "sid": message.account_sid
        }
    except SQLAlchemyError as e:
        print(e)
        db.rollback()  # Rollback in case of any database error
        raise HTTPException(
            status_code=500, detail="Database error occurred while processing match request.")
    except HTTPException as e:
        raise e  # Rethrow HTTP exceptions to avoid them being caught as 500 errors
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred.")


# Route to handle user login
@router.post("/login", status_code=200)
def login(user: UserLogin, db: Session = Depends(get_db)):
    try:
        existing_user = db.query(User).filter(User.phone == user.phone).first()

        if not existing_user:
            raise HTTPException(
                status_code=404, detail="User with this phone number does not exist!")

        stored_otp = redis_client.get(user.phone)
        if stored_otp is None:
            raise HTTPException(
                status_code=404, detail="OTP has expired or does not exist")

        if stored_otp != user.otp:
            raise HTTPException(status_code=400, detail="Invalid OTP")

        redis_client.delete(user.phone)
        token = jwt.encode({"id": existing_user.id}, jwt_secret)


        return {
            "message": "Success",
            "token": token,
            "user": {
                "id": existing_user.id,
                "name": existing_user.name,
                "phone": existing_user.phone,
                "gender": existing_user.gender,
                "dob": existing_user.dob,
                "age": existing_user.age,
                "created_at": existing_user.created_at,
                "updated_at": existing_user.updated_at,
            }
        }
    except SQLAlchemyError as e:
        db.rollback()  # Rollback in case of any database error
        raise HTTPException(
            status_code=500, detail="Database error occurred while processing match request.")
    except HTTPException as e:
        raise e  # Rethrow HTTP exceptions to avoid them being caught as 500 errors
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred.")


@router.get("/", status_code=200)
def user_data(db: Session = Depends(get_db), user_dict=Depends(auth_middleware)):
    try:
        user = db.query(User).filter(User.id == user_dict["uid"]).first()
        if not user:
            raise HTTPException(404, "User not found!")

        return {
            "message": "Success",
            "user": {
                "id": user.id,
                "name": user.name,
                "phone": user.phone,
                "gender": user.gender,
                "dob": user.dob,
                "age": user.age,
                "created_at": user.created_at,
                "updated_at": user.updated_at,
            }
        }
    except SQLAlchemyError as e:
        db.rollback()  # Rollback in case of any database error
        raise HTTPException(
            status_code=500, detail="Database error occurred while processing match request."
        )
    except HTTPException as e:
        raise e  # Rethrow HTTP exceptions to avoid them being caught as 500 errors
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred."
        )


# Route to delete all users (admin feature)
# @router.delete("/delete-users", status_code=204)
# def delete_users(db: Session = Depends(get_db)):
#     try:
#         users = db.query(User).all()
#         if not users:
#             raise HTTPException(
#                 status_code=404, detail="No users found to delete.")

#         for user in users:
#             db.delete(user)
#         db.commit()

#         return {"message": "All users deleted successfully."}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))
