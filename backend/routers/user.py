from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import models, schemas
from database import get_db
from dependencies import get_current_user

router = APIRouter()

@router.post("/register", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user_email = db.query(models.User).filter(models.User.email == user.email).first()
    db_user_phone = db.query(models.User).filter(models.User.phone == user.phone).first()
    if db_user_email or db_user_phone:
        raise HTTPException(status_code=400, detail="Email or Phone already registered")

    new_user = models.User(
        firebase_uid=user.firebase_uid,
        email=user.email,
        phone=user.phone,
        name=user.name,
        age=user.age,
        photo_url=user.photo_url,
        auto_distress_enabled=user.auto_distress_enabled,
        mic_access_enabled=user.mic_access_enabled,
        sensor_monitoring_enabled=user.sensor_monitoring_enabled
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.get("/profile/me", response_model=schemas.User)
def get_user_profile(user: models.User = Depends(get_current_user)):
    return user

@router.post("/contacts", response_model=schemas.EmergencyContact)
def add_emergency_contact(contact: schemas.EmergencyContactCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if len(user.contacts) >= 5:
        raise HTTPException(status_code=400, detail="Maximum 5 emergency contacts allowed")
        
    new_contact = models.EmergencyContact(
        name=contact.name,
        phone=contact.phone,
        owner_id=user.id
    )
    db.add(new_contact)
    db.commit()
    db.refresh(new_contact)
    return new_contact

@router.get("/contacts", response_model=list[schemas.EmergencyContact])
def get_emergency_contacts(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    contacts = db.query(models.EmergencyContact).filter(models.EmergencyContact.owner_id == user.id).all()
    return contacts
