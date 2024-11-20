# Import all models
from models.user import User
from models.asset import Asset
from models.message import Message
from models.match import Match

# Initialize relationships
User.assets
Asset.user
User.sent_messages
Message.sender
User.received_messages  # Added for recipient messages
Message.recipient       # Added for message recipient
User.matches_as_user1
User.matches_as_user2
Match.user1
Match.user2
Match.messages
Message.match

# You can add any other necessary initializations here

# This line is optional, but it can be helpful to explicitly define what should be imported when someone does `from models import *`
__all__ = ['User', 'Asset', 'Message', 'Match']