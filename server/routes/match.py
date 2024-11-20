import uuid
from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy import or_, and_
from sqlalchemy.orm import Session, joinedload
from sqlalchemy.exc import SQLAlchemyError
from typing import Optional

from models.match import Match, MatchStatus
from models.user import User
from models.asset import Asset
from config.database import get_db
from middleware.auth_middleware import auth_middleware
from schema.user_match import UserMatch

router = APIRouter()
router = APIRouter(tags=["Match"])


@router.post("/create-match")
def create_match(create_match: UserMatch, db: Session = Depends(get_db), auth_dict=Depends(auth_middleware)):
    try:
        # Prevent self-matching
        if auth_dict["uid"] == create_match.user2_id:
            raise HTTPException(
                status_code=400, detail="You cannot send a match request to yourself."
            )

        # Check if a match already exists between the two users
        existing_match = db.query(Match).filter(
            or_(
                and_(Match.user1_id ==
                     auth_dict["uid"], Match.user2_id == create_match.user2_id),
                and_(Match.user2_id ==
                     auth_dict["uid"], Match.user1_id == create_match.user2_id)
            )
        ).first()

        if existing_match:
            # Handle different match statuses
            if existing_match.status == MatchStatus.UNMATCHED:
                if existing_match.user1_id == auth_dict["uid"]:
                    raise HTTPException(
                        status_code=409, detail="Match request has already been sent. Awaiting response from the other user."
                    )
                else:
                    # The other user is responding, so change the status to ACTIVE
                    existing_match.status = MatchStatus.ACTIVE
                    db.commit()
                    return {
                        "message": "You are now matched!",
                        "match": {
                            "id": existing_match.id,
                            "user1_id": existing_match.user1_id,
                            "user2_id": existing_match.user2_id,
                            "status": existing_match.status,
                            "created_at": existing_match.created_at,
                            "updated_at": existing_match.updated_at,
                        }
                    }

            elif existing_match.status == MatchStatus.ACTIVE:
                # If the existing match is ACTIVE, inform the user
                raise HTTPException(
                    status_code=409, detail="You are already matched with this user."
                )

            elif existing_match.status == MatchStatus.REJECTED:
                # If the existing match is REJECTED, inform the user
                raise HTTPException(
                    status_code=409, detail="The other user rejected your request."
                )

        # If no existing match, create a new one with status UNMATCHED
        new_match = Match(
            id=str(uuid.uuid4()),
            user1_id=auth_dict["uid"],
            user2_id=create_match.user2_id,
            status=MatchStatus.UNMATCHED
        )
        db.add(new_match)
        db.commit()
        db.refresh(new_match)

        return {
            "message": "New match request sent with status UNMATCHED",
            "match": {
                "id": new_match.id,
                "user1_id": new_match.user1_id,
                "user2_id": new_match.user2_id,
                "status": new_match.status,
                "created_at": new_match.created_at,
                "updated_at": new_match.updated_at,
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


@router.post("/reject-match")
def reject_match(create_match: UserMatch, db: Session = Depends(get_db), auth_dict=Depends(auth_middleware)):
    try:
        # Check if a match already exists between the two users
        existing_match = db.query(Match).filter(
            or_(
                and_(Match.user1_id ==
                     auth_dict["uid"], Match.user2_id == create_match.user2_id),
                and_(Match.user2_id ==
                     auth_dict["uid"], Match.user1_id == create_match.user2_id)
            )
        ).first()

        if existing_match:
            # If the match is already rejected, inform the user
            if existing_match.status == MatchStatus.REJECTED:
                return {"message": "You have already rejected this match request."}

            # If the match is active, or unmatched, set it to rejected
            existing_match.status = MatchStatus.REJECTED
            db.commit()
            return {
                "message": "Match request rejected successfully.",
                "match": {
                    "id": existing_match.id,
                    "user1_id": existing_match.user1_id,
                    "user2_id": existing_match.user2_id,
                    "status": existing_match.status,
                    "created_at": existing_match.created_at,
                    "updated_at": existing_match.updated_at,
                }
            }

        # If no match exists, create a new one with rejected status
        new_match = Match(
            id=str(uuid.uuid4()),
            user1_id=auth_dict["uid"],
            user2_id=create_match.user2_id,
            status=MatchStatus.REJECTED
        )
        db.add(new_match)
        db.commit()
        db.refresh(new_match)

        return {
            "message": "Match request rejected.",
            "match": {
                "id": new_match.id,
                "user1_id": new_match.user1_id,
                "user2_id": new_match.user2_id,
                "status": new_match.status,
                "created_at": new_match.created_at,
                "updated_at": new_match.updated_at,
            }
        }

    except SQLAlchemyError as e:
        db.rollback()  # Rollback in case of any database error
        raise HTTPException(
            status_code=500, detail="Database error occurred while rejecting match request."
        )
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise HTTPException(
            status_code=500, detail="An unexpected error occurred while rejecting match request."
        )


@router.get("/match-profile")
def match_profiles(
    match_status: str,
    db: Session = Depends(get_db),
    auth_dict=Depends(auth_middleware)
):
    try:
        # Get the current user's ID
        current_user_id = auth_dict["uid"]

        # Query to get matches where the current user is either user1 or user2 with the specified status
        matches = db.query(Match).filter(
            and_(
                Match.status == match_status,
                or_(
                    Match.user1_id == current_user_id,
                    Match.user2_id == current_user_id
                ),
            )
        ).all()

        # Extract the other user's ID for each match
        other_user_ids = [
            match.user2_id if match.user1_id == current_user_id else match.user1_id
            for match in matches
        ]

        # Retrieve user details for the other users
        match_users = db.query(User).filter(User.id.in_(
            other_user_ids)).options(joinedload(User.assets)).all()

        match_profiles = [
            {
                "id": user.id,
                "name": user.name,
                "dob": user.dob,
                "phone": user.phone,
                "gender": user.gender,
                "created_at": user.created_at,
                "updated_at": user.updated_at,
                "assets": user.assets,
                "age": user.age  # Calculate age and add it here
            }
            for user in match_users
        ]

        return {
            "message": f"Profiles found successfully for user id {current_user_id}",
            "users": match_profiles
        }

    except SQLAlchemyError:
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


@router.get("/suggest-profile-for-match")
def suggest_match_profile(
    db: Session = Depends(get_db),
    auth_dict=Depends(auth_middleware),
    passion_list: Optional[str] = Query(None),
    page: int = Query(1, gt=0),
    page_size: int = Query(10, gt=0),
    low_age: int = Query(18),
    up_age: int = Query(100),
    gender: str = Query("BOTH", regex="^(MALE|FEMALE|BOTH)$")
):
    try:
        # Get user ID from auth_dict
        current_user_id = auth_dict["uid"]

        # Get IDs of users that have active or rejected matches with the current user
        active_rejected_user_ids = db.query(Match.user1_id).filter(
            Match.user2_id == current_user_id,
            or_(Match.status == MatchStatus.ACTIVE,
                Match.status == MatchStatus.REJECTED)
        ).all() + db.query(Match.user2_id).filter(
            Match.user1_id == current_user_id,
            or_(Match.status == MatchStatus.ACTIVE,
                Match.status == MatchStatus.REJECTED)
        ).all()

        # Flatten the list and use a set for uniqueness
        active_rejected_user_ids = set(user_id for (
            user_id,) in active_rejected_user_ids)

        # Get IDs of users that the current user has sent unmatched requests to
        unmatched_sent_user_ids = db.query(Match.user2_id).filter(
            Match.user1_id == current_user_id,
            # Ensure we only get unmatched requests sent by current user
            Match.status == MatchStatus.UNMATCHED
        ).all()

        # Get IDs of users that have sent unmatched requests to the current user
        unmatched_received_user_ids = db.query(Match.user1_id).filter(
            Match.user2_id == current_user_id,
            # Ensure we only get unmatched requests received by current user
            Match.status == MatchStatus.UNMATCHED
        ).all()

        # Flatten the list of unmatched user IDs and use a set for uniqueness
        unmatched_sent_user_ids = set(user_id for (
            user_id,) in unmatched_sent_user_ids)
        unmatched_received_user_ids = set(user_id for (
            user_id,) in unmatched_received_user_ids)

        # Combine the user IDs of unmatched sent requests with those having active/rejected matches
        filtered_user_ids = active_rejected_user_ids.union(
            unmatched_sent_user_ids)

        # Parse passion_list from a comma-separated string to a list
        passions = passion_list.split(",") if passion_list else []

        # Query to find users excluding the authenticated user and users with active/rejected matches
        query = db.query(User).filter(
            User.id != current_user_id,
            # Exclude users that have active/rejected matches or unmatched sent requests
            User.id.notin_(filtered_user_ids)
        ).options(joinedload(User.assets))

        # Apply age filter
        query = query.filter(
            User.age >= low_age,
            User.age <= up_age
        )
        # Apply gender filter if gender is not "BOTH"
        if gender != "BOTH":
            query = query.filter(User.gender == gender)

        # Filter profiles based on passions if any are provided
        if passions:
            query = query.join(User.assets).filter(
                or_(*[Asset.passion_list.any(passion) for passion in passions])
            )

        # Paginate results if page and page_size are provided
        profiles = query.offset((page - 1) * page_size).limit(page_size).all()

        # Check if profiles are empty and raise an exception if so
        if not profiles:
            raise HTTPException(
                status_code=404, detail="No more profiles to show.")

        profile_data = [
            {
                "id": user.id,
                "name": user.name,
                "dob": user.dob,
                "phone": user.phone,
                "gender": user.gender,
                "created_at": user.created_at,
                "updated_at": user.updated_at,
                "assets": user.assets,
                "age": user.age
            }
            for user in profiles
        ]

        return {
            "message": f"Profiles found successfully for match for user id {current_user_id}",
            "users": profile_data,
        }

    except SQLAlchemyError:
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
