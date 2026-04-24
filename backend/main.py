import uvicorn
from fastapi import FastAPI
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

from database import engine, Base

# Create database tables
Base.metadata.create_all(bind=engine)

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Smart Women Safety Analytics System API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

from routers import user, sos, analytics, tracking, telemetry

app.include_router(user.router, prefix="/api", tags=["Users"])
app.include_router(sos.router, prefix="/api", tags=["SOS"])
app.include_router(analytics.router, prefix="/api", tags=["Analytics"])
app.include_router(tracking.router, prefix="/api", tags=["Tracking"])
app.include_router(telemetry.router, prefix="/api", tags=["Telemetry WebSocket"])

@app.get("/")
def read_root():
    return {"message": "Welcome to SWSAS Backend. Go to /docs for API documentation."}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
