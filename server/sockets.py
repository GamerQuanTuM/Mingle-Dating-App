from starlette.applications import Starlette
from fastapi import HTTPException
import socketio
from datetime import datetime
from sqlalchemy import or_, and_
import uuid
from config.supabase_client import upload_to_supabase
import base64
from io import BytesIO

from models.match import Match, MatchStatus
from config.database import get_db_socket
from models.message import Message

# Socket.IO event server
sio_server = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins=[],
    transports=['websocket', 'polling'],
    engineio_logger=True
)


# Dictionary to store user session information
user_sessions = {}


@sio_server.event
async def connect(sid, data):
    print(f'{sid}: trying to connect')


@sio_server.event
async def login(sid, data):
    user_id = data.get('user_id')
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")

    print(f'{sid}: User ID received: {user_id}')

    try:
        if user_id not in user_sessions:
            user_sessions[user_id] = {
                'socket_id': sid,
                'status': 'ONLINE',
                'timestamp': datetime.now().isoformat()
            }
        else:
            user_sessions[user_id]['socket_id'] = sid
            user_sessions[user_id]['status'] = 'ONLINE'
            user_sessions[user_id]['timestamp'] = datetime.now().isoformat()

        await sio_server.emit('join', {'online_users': user_sessions})
        print(f'{user_id} connected')

    except HTTPException as e:
        print(f"Authentication failed for sid {sid}: {e.detail}")
        await sio_server.disconnect(sid)
        raise e


@sio_server.event
async def chat(sid, data):
    try:
        if data and isinstance(data, dict):
            current_user_id = data.get('current_user_id')
            message_user_id = data.get('message_user_id')
            chat_message = data.get('message')
            file = data.get('file')

            if current_user_id and message_user_id:
                with get_db_socket() as db:
                    existing_match = db.query(Match).filter(
                        or_(
                            and_(Match.user1_id == current_user_id,
                                 Match.user2_id == message_user_id),
                            and_(
                                Match.user1_id == message_user_id,
                                Match.user2_id == current_user_id,
                            )
                        )
                    ).first()

                    if existing_match is None:
                        print("No match found between these users")
                        return
                    elif existing_match.status != MatchStatus.ACTIVE:
                        print(
                            "Can't send a message to the user whom you are not actively matched with")
                        return

                    file_url = None
                    file_type = "text"

                    if file is not None:
                        try:
                            class MockUploadFile:
                                def __init__(self, content, filename, content_type):
                                    self.content = content
                                    self.filename = filename
                                    self.content_type = content_type

                                async def read(self):
                                    return self.content

                            decoded_file = base64.b64decode(file)
                            mock_file = MockUploadFile(
                                content=decoded_file,
                                filename=data.get('filename', 'file'),
                                content_type=data.get(
                                    'content_type', 'image/jpg')
                            )

                            file_url = await upload_to_supabase(
                                mock_file,
                                'message_file',
                                current_user_id + "..." + message_user_id
                            )
                            file_type = "file"
                        except Exception as e:
                            print(f"File upload error: {str(e)}")
                            # Handle the error appropriately

                    new_message = Message(
                        id=str(uuid.uuid4()),
                        match_id=existing_match.id,
                        sender_id=current_user_id,
                        recipient_id=message_user_id,
                        content=chat_message,
                        file_url=file_url,
                        content_type=file_type
                    )
                    db.add(new_message)
                    db.commit()
                    db.refresh(new_message)

                    message_dict = {
                        "id": str(new_message.id),
                        "match_id": str(new_message.match_id),
                        "sender_id": str(new_message.sender_id),
                        "recipient_id": str(new_message.recipient_id),
                        "content": new_message.content,
                        "content_type": str(new_message.content_type),
                        "file_url": new_message.file_url,
                        "seen": new_message.seen,
                        "created_at": new_message.created_at.isoformat(),
                        "updated_at": new_message.updated_at.isoformat()
                    }

                    await sio_server.emit("chat", message_dict)

                    if message_user_id in user_sessions:
                        recipient_socket_id = user_sessions[message_user_id]['socket_id']
                        await sio_server.emit("chat_message", {
                            "sender_id": current_user_id,
                            "recipient_id": message_user_id,
                            "content": chat_message
                        }, room=recipient_socket_id)

    except HTTPException as e:
        await sio_server.disconnect(sid)
        raise e


@sio_server.event
async def mark_messages_seen(sid, data):
    try:
        if data and isinstance(data, dict):
            current_user_id = data.get('current_user_id')
            sender_id = data.get('sender_id')

            with get_db_socket() as db:
                # Update messages as seen
                db.query(Message).filter(
                    Message.sender_id == sender_id,
                    Message.recipient_id == current_user_id,
                    Message.seen == False
                ).update({"seen": True})
                db.commit()

                # Emit message_seen event to sender
                if sender_id in user_sessions:
                    sender_socket_id = user_sessions[sender_id]['socket_id']
                    await sio_server.emit("message_seen", {
                        "sender_id": sender_id,
                        "reader_id": current_user_id
                    }, room=sender_socket_id)

    except Exception as e:
        print(f"Error marking messages as seen: {e}")


@sio_server.event
async def disconnect(sid):
    print(f'{sid}: disconnecting')


@sio_server.event
async def logout(sid, data):
    user_id = data.get('user_id')
    if user_id in user_sessions:
        user_sessions[user_id]['status'] = 'OFFLINE'
        user_sessions[user_id]['timestamp'] = datetime.now().isoformat()
        await sio_server.emit('leave', {'user_id': user_id})
        print(f'{user_id} logged out')
        print(f'Users connected === {user_sessions}')

app = Starlette(debug=True)
app.mount('/sockets/', sio_server)
