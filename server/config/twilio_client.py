from twilio.rest import Client
import os
from dotenv import load_dotenv

load_dotenv()

twilio_account_sid = os.getenv('TWILIO_ACCOUNT_SID')
twilio_auth_token = os.getenv('TWILIO_AUTH_TOKEN')
twilio_phone_number = os.getenv('TWILIO_PHONE_NUMBER')

twilio_client = Client(twilio_account_sid, twilio_auth_token)