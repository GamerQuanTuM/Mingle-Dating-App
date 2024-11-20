from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
from dotenv import load_dotenv
from starlette.applications import Starlette
import socketio

from config.database import engine
from models.base import Base
from routes import auth, asset, match,profile,message
from sockets import sio_server

load_dotenv()

app = FastAPI()

# app.mount('/', app=sio_app)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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

app = sio_app

if __name__ == "__main__":
    uvicorn.run("main:app", reload=True, host="0.0.0.0")
