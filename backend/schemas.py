from pydantic import BaseModel
from typing import List, Optional
import datetime

class EmergencyContactBase(BaseModel):
    name: str
    phone: str

class EmergencyContactCreate(EmergencyContactBase):
    pass

class EmergencyContact(EmergencyContactBase):
    id: int
    owner_id: int

    class Config:
        from_attributes = True

class UserBase(BaseModel):
    email: str
    phone: Optional[str] = None
    name: str
    age: int
    photo_url: Optional[str] = None
    auto_distress_enabled: bool = True
    mic_access_enabled: bool = False
    sensor_monitoring_enabled: bool = True

class UserCreate(UserBase):
    firebase_uid: str

class User(UserBase):
    id: int
    firebase_uid: str
    contacts: List[EmergencyContact] = []

    class Config:
        from_attributes = True

class SosAlertBase(BaseModel):
    trigger_type: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    audio_url: Optional[str] = None

class SosAlertCreate(SosAlertBase):
    pass

class EmergencyCallTrigger(BaseModel):
    lat: float
    lng: float
    trigger_type: str  # e.g., "manual", "auto"

class ContactPhoneUpdate(BaseModel):
    phone: str

class SosAlert(SosAlertBase):
    id: int
    user_id: int
    status: str
    timestamp: datetime.datetime

    class Config:
        from_attributes = True

class IncidentBase(BaseModel):
    lat: float
    lng: float
    type: str

class ReportIncidentPayload(BaseModel):
    latitude: float
    longitude: float
    incident_type: str
    timestamp: Optional[datetime.datetime] = None

class IncidentCreate(IncidentBase):
    timestamp: Optional[datetime.datetime] = None

class Incident(IncidentBase):
    id: int
    user_id: int
    timestamp: datetime.datetime

    class Config:
        from_attributes = True

class JourneyCreate(BaseModel):
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None

class Journey(BaseModel):
    id: int
    user_id: int
    start_time: datetime.datetime
    end_time: Optional[datetime.datetime] = None
    status: str
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None

    class Config:
        from_attributes = True

class LocationHistoryBase(BaseModel):
    lat: float
    lng: float
    journey_id: Optional[int] = None

class LocationHistoryCreate(LocationHistoryBase):
    pass

class LocationHistory(LocationHistoryBase):
    id: int
    user_id: int
    timestamp: datetime.datetime

    class Config:
        from_attributes = True
