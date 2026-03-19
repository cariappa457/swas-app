from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
import models, schemas
from database import get_db
import datetime
from dependencies import get_current_user

router = APIRouter()

def send_emergency_sms(user: models.User, lat: float, lng: float, db: Session):
    """Background task to notify contacts without blocking the API response"""
    contacts = db.query(models.EmergencyContact).filter(models.EmergencyContact.owner_id == user.id).all()
    location_url = f"https://maps.google.com/?q={lat},{lng}"
    
    for contact in contacts:
        message = f"URGENT: {user.name} has triggered an SOS! Live location: {location_url}"
        # Trigger actual SMS gateway here (Twilio, AWS SNS, Msg91)
        print(f"Sending SMS to {contact.phone}: {message}")

@router.post("/sos/trigger-call")
def trigger_emergency_call(
    payload: schemas.EmergencyCallTrigger, 
    background_tasks: BackgroundTasks,
    user: models.User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    # 1. Rate Limiting Check (Prevent abuse)
    now = datetime.datetime.utcnow()
    if user.last_emergency_call_time:
        time_diff = (now - user.last_emergency_call_time).total_seconds()
        if time_diff < 60: # 1 minute cooldown
            raise HTTPException(status_code=429, detail="SOS triggered too recently.")

    # 2. Update status and log
    user.sos_status = "active_sos"
    user.last_emergency_call_time = now
    
    new_alert = models.SosAlert(
        user_id=user.id,
        trigger_type=payload.trigger_type,
        status="active",
        lat=payload.lat,
        lng=payload.lng
    )
    db.add(new_alert)
    db.commit()

    # 3. Queue SMS Notifications to contacts securely
    background_tasks.add_task(send_emergency_sms, user, payload.lat, payload.lng, db)

    return {"message": "Emergency protocol initiated. Contacts notified."}

@router.post("/sos/trigger", response_model=schemas.SosAlert)
def trigger_sos(alert: schemas.SosAlertCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    new_alert = models.SosAlert(
        user_id=user.id,
        trigger_type=alert.trigger_type,
        status="active",
        lat=alert.lat,
        lng=alert.lng,
        audio_url=alert.audio_url
    )
    
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    
    return new_alert

@router.post("/sos/cancel/{alert_id}", response_model=schemas.SosAlert)
def cancel_sos(alert_id: int, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    alert = db.query(models.SosAlert).filter(models.SosAlert.id == alert_id, models.SosAlert.user_id == user.id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
        
    alert.status = "cancelled"
    
    # Restore User status
    if user.sos_status == "active_sos":
        user.sos_status = "inactive"

    db.commit()
    db.refresh(alert)
    return alert

# Real-time Location Sharing Endpoint Placeholder
@router.post("/location/live")
def update_live_location(lat: float, lng: float, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    return {"message": "Location updated", "lat": lat, "lng": lng, "user": user.name}
