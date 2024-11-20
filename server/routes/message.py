from fastapi import HTTPException, Depends
from sqlalchemy.orm import aliased
from sqlalchemy import or_, func
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from config.database import get_db
from models.asset import Asset
from models.message import Message
from models.user import User
from middleware.auth_middleware import auth_middleware
from schema.message_users import MessageUsers
from schema.unseen_message_count import UnseenMessageCount


router = APIRouter(tags=["Message"])


@router.post("/get-message-between-two-users", status_code=200)
def message_between_two_users(messageUser: MessageUsers, db: Session = Depends(get_db), user_dict=Depends(auth_middleware)):
    try:
        current_user_id = user_dict["uid"]
        message_user_id = messageUser.message_user_id
        messages = db.query(Message).filter(
            or_(
                and_(
                    Message.sender_id == current_user_id,
                    Message.recipient_id == message_user_id,),
                and_(
                    Message.sender_id == message_user_id,
                    Message.recipient_id == current_user_id,)
            )
        ).all()
        return messages
    except HTTPException as e:
        raise e  # Rethrow HTTP exceptions to avoid them being caught as 500 errors
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred."
        )


@router.get("/messages-user")
def messages_user(db: Session = Depends(get_db), user_dict=Depends(auth_middleware)):
    try:
        current_user_id = user_dict["uid"]

        # Step 1: Fetch messages with basic details (without joining user or assets yet)
        last_message_subquery = (
            db.query(
                Message.match_id,
                func.max(Message.created_at).label("last_message_time")
            )
            .filter(
                or_(
                    Message.sender_id == current_user_id,
                    Message.recipient_id == current_user_id
                )
            )
            .group_by(Message.match_id)
            .subquery()
        )

        messages = (
            db.query(
                Message.id.label("message_id"),
                Message.match_id,
                Message.content.label("last_message_content"),
                Message.created_at.label("last_message_time"),
                Message.sender_id,
                Message.recipient_id
            )
            .join(last_message_subquery,
                  (Message.match_id == last_message_subquery.c.match_id) &
                  (Message.created_at == last_message_subquery.c.last_message_time))
            .filter(
                or_(
                    Message.sender_id == current_user_id,
                    Message.recipient_id == current_user_id
                )
            )
            .order_by(last_message_subquery.c.last_message_time.desc())
            .all()
        )

        # Step 2: Process each message to determine the other user's details
        response = []
        for message in messages:
            other_user_id = None
            if message.sender_id == current_user_id:
                other_user_id = message.recipient_id
            elif message.recipient_id == current_user_id:
                other_user_id = message.sender_id

            # Step 3: Fetch the other user's details and assets
            user_details = (
                db.query(
                    User.id,
                    User.name,
                    User.phone,
                    User.dob,
                    User.age,
                    User.gender,
                    User.created_at,
                    User.updated_at
                )
                .filter(User.id == other_user_id)
                .first()
            )

            # Fetch user assets if they exist
            user_assets = (
                db.query(
                    Asset.id,
                    Asset.user_id,
                    Asset.profile_picture,
                    Asset.image_list,
                    Asset.passion_list,
                    Asset.created_at,
                    Asset.updated_at
                )
                .filter(Asset.user_id == other_user_id)
                .first()
            )

            # Construct the response for the current message and the other user's details and assets
            message_response = {
                "message_id": message.message_id,
                "match_id": message.match_id,
                "last_message_content": message.last_message_content or "You have not messaged anyone yet",
                "last_message_time": message.last_message_time,
                "sender_id": message.sender_id,
                "interacted_user_details": {
                    "id": user_details.id,
                    "name": user_details.name,
                    "phone": user_details.phone,
                    "dob": user_details.dob,
                    "age": user_details.age,
                    "gender": user_details.gender,
                    "created_at": user_details.created_at,
                    "updated_at": user_details.updated_at,
                },
            }

            # Add the user assets field only if asset data exists
            if user_assets:
                message_response["interacted_user_assets"] = {
                    "id": user_assets.id,
                    "user_id": user_assets.user_id,
                    "profile_picture": user_assets.profile_picture,
                    "image_list": user_assets.image_list or [],
                    "passion_list": user_assets.passion_list or [],
                    "created_at": user_assets.created_at,
                    "updated_at": user_assets.updated_at,
                }

            response.append(message_response)

        return response

    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred."
        )


@router.post("/unseen-messages-count")
def unseen_messages_count(unseen_message_count: UnseenMessageCount, db: Session = Depends(get_db), user_dict=Depends(auth_middleware)):
    try:
        current_user_id = user_dict["uid"]
        recipient_id = unseen_message_count.recipient_id
        unseen_count = db.query(Message).filter(
            Message.sender_id == recipient_id,
            Message.recipient_id == current_user_id,
            Message.seen == False,
        ).count()

        return {"message": unseen_count}
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred."
        )


@router.post("/update-seen-messages")
def update_seen_messages(
    unseen_message_count: UnseenMessageCount,
    db: Session = Depends(get_db),
    user_dict=Depends(auth_middleware)
):
    try:
        current_user_id = user_dict["uid"]
        recipient_id = unseen_message_count.recipient_id

        # Query to update messages
        updated_rows = db.query(Message).filter(
            Message.sender_id == recipient_id,
            Message.recipient_id == current_user_id,
            Message.seen == False
        ).update({"seen": True}, synchronize_session=False)

        # Commit changes
        db.commit()

        return {"message": 0}
    except HTTPException as e:
        raise e
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred."
        )
