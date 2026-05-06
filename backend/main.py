import uvicorn
from fastapi import FastAPI
from database import engine, Base
from routers import user, sos, analytics, tracking, voice

import os

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

app.include_router(user.router, prefix="/api", tags=["Users"])
app.include_router(sos.router, prefix="/api", tags=["SOS"])
app.include_router(analytics.router, prefix="/api", tags=["Analytics"])
app.include_router(tracking.router, prefix="/api", tags=["Tracking"])
app.include_router(voice.router, prefix="/api/voice", tags=["Voice"])

@app.get("/")
def read_root():
    return {"message": "Welcome to SWSAS Backend. Go to /docs for API documentation."}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
