from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from config.database import get_db
from models.user import User
from middleware.auth_middleware import auth_middleware
from schema.update_profile import UpdateProfile


router = APIRouter(tags=['Profile'])


@router.put("/update")
def update_profile(user_update: UpdateProfile, db: Session = Depends(get_db), auth_dict=Depends(auth_middleware)):
    update_name = user_update.name
    update_phone = user_update.phone
    update_dob = user_update.dob

    hasNameChange = False
    hasPhoneChange = False
    hasDobChange = False
    try:
        existing_user = db.query(User).filter(
            User.id == auth_dict["uid"]).first()

        if update_phone and update_phone != existing_user.phone:
            phone_conflict_user = db.query(User).filter(
                User.phone == update_phone, User.id != existing_user.id).first()
            if phone_conflict_user:
                raise HTTPException(
                    409, "Phone number already in use by another user.")

        if existing_user is None:
            raise HTTPException(404, "User not found.")

        update_data = {}

        if existing_user.name == update_name:
            hasNameChange = True
        else:
            update_data['name'] = update_name

        if existing_user.phone == update_phone:
            hasPhoneChange = True
        else:
            update_data['phone'] = update_phone

        if existing_user.dob == update_dob:
            hasDobChange = True
        else:
            update_data['dob'] = update_dob

        if update_data:
            db.query(User).filter(User.id == auth_dict["uid"]).update(
                update_data,
                synchronize_session=False
            )
        db.commit()
        db.refresh(existing_user)

        return {
            "message": "Profile Updated",
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
        db.rollback()
        print(str(e))
        raise HTTPException(
            500, detail="Database error occurred while processing match request.")

    except HTTPException as e:
        raise e
    except Exception as e:
        print(str(e))
        raise HTTPException(
            status_code=400, detail="An unexpected error occured.")
