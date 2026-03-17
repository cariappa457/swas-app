from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime
from sqlalchemy.orm import relationship
import datetime

from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    phone = Column(String, unique=True, index=True)
    name = Column(String)
    age = Column(Integer)
    photo_url = Column(String, nullable=True)
    
    # Settings logic
    auto_distress_enabled = Column(Boolean, default=True)
    mic_access_enabled = Column(Boolean, default=False)
    sensor_monitoring_enabled = Column(Boolean, default=True)
    
    # Emergency Call Feature Tracking
    last_emergency_call_time = Column(DateTime, nullable=True)
    sos_status = Column(String, default="inactive") # inactive, active_sos
    
    contacts = relationship("EmergencyContact", back_populates="owner")
    incidents = relationship("Incident", back_populates="user")
    sos_alerts = relationship("SosAlert", back_populates="user")

class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    phone = Column(String)
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="contacts")

class SosAlert(Base):
    __tablename__ = "sos_alerts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    trigger_type = Column(String)  # "auto", "manual", "voice", "shake", "wearable"
    status = Column(String)        # "active", "resolved", "cancelled"
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    audio_url = Column(String, nullable=True)

    user = relationship("User", back_populates="sos_alerts")

class Incident(Base):
    __tablename__ = "incidents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    lat = Column(Float)
    lng = Column(Float)
    type = Column(String) # e.g., "harassment", "robbery", "stalking"
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User", back_populates="incidents")

class Journey(Base):
    __tablename__ = "journeys"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    start_time = Column(DateTime, default=datetime.datetime.utcnow)
    end_time = Column(DateTime, nullable=True)
    status = Column(String, default="active") # active, completed
    destination_lat = Column(Float, nullable=True)
    destination_lng = Column(Float, nullable=True)
    
    user = relationship("User")

class LocationHistory(Base):
    __tablename__ = "location_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    journey_id = Column(Integer, ForeignKey("journeys.id"), nullable=True)
    lat = Column(Float)
    lng = Column(Float)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    
    user = relationship("User")
