from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from dotenv import load_dotenv
from starlette.applications import Starlette
import socketio
import requests
import threading
import logging
import schedule
import time
from datetime import datetime

from config.database import engine
from models.base import Base
from routes import auth, asset, match, profile, message
from sockets import sio_server

# Configure logging
logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - Server Health Ping - %(levelname)s: %(message)s',
    filename='server_health_ping.log'
)

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def ping_server():
    try:
        server_url = "https://mingle-dating-app.onrender.com/health"  # Adjust as needed
        
        response = requests.get(server_url, timeout=10)
        
        if response.status_code == 200:
            logging.info(f"Server health check successful at {datetime.now()}")
        else:
            logging.warning(f"Server returned non-200 status: {response.status_code}")
    
    except requests.RequestException as e:
        logging.error(f"Error pinging server: {e}")

def run_scheduler():
    schedule.every(15).minutes.do(ping_server)
    
    while True:
        schedule.run_pending()
        time.sleep(1)

@app.get('/health')
def health_check():
    return JSONResponse(content={'status': 'OK'}, status_code=200)

# Include FastAPI routes
app.include_router(auth.router, prefix="/auth")
app.include_router(asset.router, prefix="/asset")
app.include_router(match.router, prefix="/match")
app.include_router(profile.router, prefix="/profile")
app.include_router(message.router, prefix="/message")

# Create all tables
Base.metadata.create_all(engine)

starlette_app = Starlette(debug=True)
starlette_app.mount("/", app)

sio_app = socketio.ASGIApp(sio_server, starlette_app, socketio_path='/sockets')
app = sio_app

if __name__ == "__main__":
    # Start scheduler in a separate thread
    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()
    
    # Run the server
    uvicorn.run("main:app", reload=True, host="0.0.0.0")