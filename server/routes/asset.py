import ast
from typing import Optional, List
import uuid
from fastapi import APIRouter, HTTPException, UploadFile, Form, Depends, File
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from models.user import User
from config.database import get_db
from config.supabase_client import upload_to_supabase
from middleware.auth_middleware import auth_middleware
from models.asset import Asset

router = APIRouter()


@router.post("/upload", status_code=201)
async def upload_assets(
        user_id: str = Form(...),
        image_list: Optional[List[UploadFile]] = File(None),
        profile_picture: Optional[UploadFile] = File(None),
        passion_list: Optional[List[str]] = Form(None),
        db: Session = Depends(get_db)):

    try:
        # Check if user exists in the database
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User does not exist")

        asset_id = str(uuid.uuid4())
        uploaded_image_list = []
        uploaded_passion_list = passion_list if passion_list else []

    # Upload profile picture if provided
        profile_pic = None
        if profile_picture:
            profile_pic = await upload_to_supabase(profile_picture, "profile_picture", user_id)

    # Upload images if provided
        if image_list:
            for image in image_list:
                url = await upload_to_supabase(image, "image_list", user_id)
                uploaded_image_list.append(url)

    # Create and save the asset
        uploaded_passion_list[0] = ast.literal_eval(uploaded_passion_list[0])
        asset = Asset(
            id=asset_id,
            profile_picture=profile_pic,
            passion_list=uploaded_passion_list[0],
            image_list=uploaded_image_list,
            user_id=user.id,
        )
        db.add(asset)
        db.commit()
        db.refresh(asset)

        return {"message": "Upload completed successfully", "asset_id": asset_id}
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


@router.get("/")
def get_assets(db: Session = Depends(get_db), user_dict=Depends(auth_middleware)):
    try:
        assets = db.query(Asset).filter(
            Asset.user_id == user_dict["uid"]).first()

        if not assets:
            raise HTTPException(
                status_code=404, detail="Assets does not exist")

        return {
            "id": assets.id,
            "profile_picture": assets.profile_picture,
            "passion_list": assets.passion_list,
            "image_list": assets.image_list,
            "user_id": assets.user_id,
            "created_at": assets.created_at,
            "updated_at": assets.updated_at,
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


@router.get("/get-asset-by-userId")
def get_assets_by_userId(user_id: str, db: Session = Depends(get_db), user_dict=Depends(auth_middleware)):
    try:
        assets = db.query(Asset).filter(
            Asset.user_id == user_id).first()

        if not assets:
            raise HTTPException(
                status_code=404, detail="Assets does not exist")

        return {
            "id": assets.id,
            "profile_picture": assets.profile_picture,
            "passion_list": assets.passion_list,
            "image_list": assets.image_list,
            "user_id": assets.user_id,
            "created_at": assets.created_at,
            "updated_at": assets.updated_at,
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


@router.post("/update-image-list", status_code=200)
async def update_image_list(
        image_list: Optional[List[UploadFile]] = File(None),
        edit_image_index: Optional[List[str]] = Form(None),
        user_dict=Depends(auth_middleware),
        db: Session = Depends(get_db)):

    try:
        # Check if the user exists in the database
        user = db.query(User).filter(User.id == user_dict["uid"]).first()
        if not user:
            raise HTTPException(status_code=404, detail="User does not exist")

        # Fetch the user's asset record
        user_asset = db.query(Asset).filter(Asset.user_id == user.id).first()

        # Convert edit_image_index to list of integers if provided
        edit_indices = list(map(int, ast.literal_eval(edit_image_index[0]))) if edit_image_index else []

        # Initialize the updated_image_list based on user_asset existence
        if user_asset:
            updated_image_list = user_asset.image_list or []
        else:
            # If user_asset does not exist, create a new one
            updated_image_list = []
            user_asset = Asset(
                id=str(uuid.uuid4()),
                profile_picture="",
                passion_list=[],
                image_list=updated_image_list,
                user_id=user.id,
            )
            db.add(user_asset)

        # Add new images to the list at specified indices
        for idx, new_image in zip(edit_indices, image_list):
            # Upload the new image and get its URL
            new_image_url = await upload_to_supabase(new_image, "image_list", user.id)

            # Replace or append the image at the specified index
            if idx < len(updated_image_list):
                updated_image_list[idx] = new_image_url  # Replace image
            else:
                # Append if index exceeds current list length
                updated_image_list.append(new_image_url)

        # Update the asset's image_list with modified data
        user_asset.image_list = updated_image_list
        db.commit()
        db.refresh(user_asset)

        return {
            "id": user_asset.id,
            "profile_picture": user_asset.profile_picture,
            "passion_list": user_asset.passion_list,
            "image_list": user_asset.image_list,
            "user_id": user_asset.user_id,
            "created_at": user_asset.created_at,
            "updated_at": user_asset.updated_at
        }

    except SQLAlchemyError:
        db.rollback()  # Rollback in case of any database error
        raise HTTPException(
            status_code=500, detail="Database error occurred while processing image list update."
        )
    except HTTPException as e:
        raise e  # Rethrow HTTP exceptions to avoid them being caught as 500 errors
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred."
        )


@router.post("/update-profile-picture", status_code=200)
async def update_profile_picture(
        profile_picture: Optional[UploadFile] = File(None),
        user_dict=Depends(auth_middleware),
        db: Session = Depends(get_db)):

    try:
        # Check if the user exists in the database
        user = db.query(User).filter(User.id == user_dict["uid"]).first()
        if not user:
            raise HTTPException(status_code=404, detail="User does not exist")

        # Fetch the user's asset record
        user_asset = db.query(Asset).filter(Asset.user_id == user.id).first()

        if profile_picture:
            profile_picture_url = await upload_to_supabase(profile_picture, "profile_picture", user.id)
        else:
            profile_picture_url = None

        if not user_asset:
            # Create a new asset record if one doesn't exist
            asset = Asset(
                id=str(uuid.uuid4()),
                profile_picture=profile_picture_url,
                passion_list=[],
                image_list=[],
                user_id=user.id,
            )
            db.add(asset)
            db.commit()
            db.refresh(asset)
            return {
                "id": asset.id,
                "profile_picture": asset.profile_picture,
                "passion_list": asset.passion_list,
                "image_list": asset.image_list,
                "user_id": asset.user_id,
                "created_at": asset.created_at,
                "updated_at": asset.updated_at
            }

        # Update the existing asset's profile picture if provided
        if profile_picture_url:
            db.query(Asset).filter(Asset.user_id == user.id).update(
                {"profile_picture": profile_picture_url},
                synchronize_session=False
            )
            db.commit()
            db.refresh(user_asset)

        return {
            "id": user_asset.id,
            "profile_picture": user_asset.profile_picture,
            "passion_list": user_asset.passion_list,
            "image_list": user_asset.image_list,
            "user_id": user_asset.user_id,
            "created_at": user_asset.created_at,
            "updated_at": user_asset.updated_at
        }

    except SQLAlchemyError:
        db.rollback()  # Rollback in case of any database error
        raise HTTPException(
            status_code=500, detail="Database error occurred while processing image list update."
        )
    except HTTPException as e:
        raise e  # Rethrow HTTP exceptions to avoid them being caught as 500 errors
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred."
        )
