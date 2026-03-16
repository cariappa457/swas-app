from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import models, schemas
from database import get_db
router = APIRouter()

@router.post("/register", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
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

@router.get("/profile/{user_id}", response_model=schemas.User)
def get_user_profile(user_id: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/profile/{user_id}/contacts", response_model=schemas.EmergencyContact)
def add_emergency_contact(user_id: int, contact: schemas.EmergencyContactCreate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if len(user.contacts) >= 5:
        raise HTTPException(status_code=400, detail="Maximum 5 emergency contacts allowed")
        
    new_contact = models.EmergencyContact(
        name=contact.name,
        phone=contact.phone,
        owner_id=user_id
    )
    db.add(new_contact)
    db.commit()
    db.refresh(new_contact)
    return new_contact

@router.get("/profile/{user_id}/contacts", response_model=list[schemas.EmergencyContact])
def get_emergency_contacts(user_id: int, db: Session = Depends(get_db)):
    contacts = db.query(models.EmergencyContact).filter(models.EmergencyContact.owner_id == user_id).all()
    return contacts
