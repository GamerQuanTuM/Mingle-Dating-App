import redis
from dotenv import load_dotenv
import os

load_dotenv()

port=os.getenv('REDIS_PORT')
username=os.getenv('REDIS_USERNAME')
password=os.getenv('REDIS_PASSWORD')
host=os.getenv('REDIS_HOST')

# redis_client = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

# Updated Redis client configuration
redis_client = redis.Redis(
    host=host,
    port=port,
    username=username,
    password=password,
    decode_responses=True
)
