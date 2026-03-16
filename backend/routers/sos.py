from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import models, schemas
from database import get_db
import datetime

router = APIRouter()

@router.post("/sos/trigger", response_model=schemas.SosAlert)
def trigger_sos(alert: schemas.SosAlertCreate, user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    new_alert = models.SosAlert(
        user_id=user_id,
        trigger_type=alert.trigger_type,
        status="active",
        lat=alert.lat,
        lng=alert.lng,
        audio_url=alert.audio_url
    )
    
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    
    # In a real app, this is where we would trigger push notifications,
    # SMS alerts using Twilio to the emergency contacts,
    # and possibly alert local authorities
    
    # contacts = db.query(models.EmergencyContact).filter(models.EmergencyContact.owner_id == user_id).all()
    # for contact in contacts:
    #     send_sms_alert(contact.phone, f"SOS from {user.name}! Location: https://maps.google.com/?q={alert.lat},{alert.lng}")
    
    return new_alert

@router.post("/sos/cancel/{alert_id}", response_model=schemas.SosAlert)
def cancel_sos(alert_id: int, db: Session = Depends(get_db)):
    alert = db.query(models.SosAlert).filter(models.SosAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
        
    alert.status = "cancelled"
    db.commit()
    db.refresh(alert)
    return alert

# Real-time Location Sharing Endpoint Placeholder
@router.post("/location/live/{user_id}")
def update_live_location(user_id: int, lat: float, lng: float, db: Session = Depends(get_db)):
    # This would typically store in Redis or Firebase Realtime DB for very fast updates 
    # instead of a relational DB. Added basic endpoint structure as a placeholder.
    return {"message": "Location updated", "lat": lat, "lng": lng}
