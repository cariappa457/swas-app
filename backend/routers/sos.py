from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List
import models, schemas
from database import get_db
import datetime
from dependencies import get_current_user

router = APIRouter()

import os
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
import logging

# Set up logging for background tasks
logger = logging.getLogger(__name__)

def send_emergency_sms(user: models.User, lat: float, lng: float, db: Session):
    """Background task to notify contacts via Twilio SMS without blocking the API response"""
    contacts = db.query(models.EmergencyContact).filter(models.EmergencyContact.owner_id == user.id).all()
    location_url = f"https://maps.google.com/?q={lat},{lng}"
    message_body = f"URGENT: {user.name} has triggered an SOS! Live location: {location_url}"
    
    # Twilio Configuration
    account_sid = os.environ.get('TWILIO_ACCOUNT_SID')
    auth_token = os.environ.get('TWILIO_AUTH_TOKEN')
    from_phone = os.environ.get('TWILIO_PHONE_NUMBER')

    if not all([account_sid, auth_token, from_phone]):
        logger.warning("Twilio credentials missing. Falling back to dummy SMS logging.")
        print("====== [TWILIO SIMULATION] ======")
        for contact in contacts:
            print(f"📞 SENDING SMS -> {contact.phone}")
            print(f"✉️ BODY: {message_body}")
            logger.info(f"[DUMMY SMS] To: {contact.phone} | Body: {message_body}")
        print("=================================")
        return

    try:
        client = Client(account_sid, auth_token)
    except Exception as e:
        logger.error(f"Failed to initialize Twilio client: {str(e)}")
        return
        
    for contact in contacts:
        if not contact.phone:
            continue
            
        try:
            message = client.messages.create(
                body=message_body,
                from_=from_phone,
                to=contact.phone
            )
            logger.info(f"Successfully sent Twilio SMS to {contact.phone}. SID: {message.sid}")
        except TwilioRestException as e:
            logger.error(f"Twilio API Error sending to {contact.phone}: {e.msg}")
        except Exception as e:
             logger.error(f"Unexpected error sending SMS to {contact.phone}: {str(e)}")

@router.post("/sos/trigger-call")
def trigger_emergency_call(
    payload: schemas.EmergencyCallTrigger, 
    background_tasks: BackgroundTasks,
    user: models.User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    print("\n" + "="*50)
    print(f"🚨 [BACKEND DEBUG] /sos/trigger-call HIT! 🚨")
    print(f"   User: {user.name} | Coords: {payload.lat}, {payload.lng}")
    print(f"   Trigger Type: {payload.trigger_type}")
    print("="*50 + "\n")
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
