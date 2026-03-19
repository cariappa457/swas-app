from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import models, schemas
from database import get_db
import datetime
from dependencies import get_current_user

router = APIRouter()

@router.post("/tracking/location", response_model=schemas.LocationHistory)
def update_live_location(location: schemas.LocationHistoryCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_loc = models.LocationHistory(
        user_id=user.id,
        lat=location.lat,
        lng=location.lng,
        journey_id=location.journey_id
    )
    db.add(db_loc)
    db.commit()
    db.refresh(db_loc)
    return db_loc

@router.get("/tracking/location", response_model=List[schemas.LocationHistory])
def get_location_history(limit: int = 50, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(models.LocationHistory).filter(models.LocationHistory.user_id == user.id).order_by(models.LocationHistory.timestamp.desc()).limit(limit).all()

@router.post("/tracking/journey", response_model=schemas.Journey)
def start_journey(journey: schemas.JourneyCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_journey = models.Journey(
        user_id=user.id,
        destination_lat=journey.destination_lat,
        destination_lng=journey.destination_lng,
        status="active"
    )
    db.add(db_journey)
    db.commit()
    db.refresh(db_journey)
    return db_journey

@router.put("/tracking/journey/{journey_id}/stop", response_model=schemas.Journey)
def stop_journey(journey_id: int, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    journey = db.query(models.Journey).filter(models.Journey.id == journey_id, models.Journey.user_id == user.id).first()
    if not journey:
        raise HTTPException(status_code=404, detail="Journey not found")
        
    journey.status = "completed"
    journey.end_time = datetime.datetime.utcnow()
    db.commit()
    db.refresh(journey)
    return journey

@router.get("/tracking/journey/active", response_model=schemas.Journey)
def get_active_journey(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    journey = db.query(models.Journey).filter(
        models.Journey.user_id == user.id, 
        models.Journey.status == "active"
    ).order_by(models.Journey.start_time.desc()).first()
    
    if not journey:
        raise HTTPException(status_code=404, detail="No active journey found")
    return journey
