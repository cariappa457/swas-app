from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import models, schemas
from database import get_db
import datetime
import numpy as np
from sklearn.cluster import KMeans

router = APIRouter()

def seed_dummy_incidents(db: Session):
    if db.query(models.Incident).count() == 0:
        dummy_user = db.query(models.User).first()
        if not dummy_user:
            dummy_user = models.User(
                firebase_uid="dummy_uid",
                email="dummy@example.com",
                name="Dummy Analytics User",
                age=25
            )
            db.add(dummy_user)
            db.commit()
            db.refresh(dummy_user)

        user_id = dummy_user.id
        base_lat, base_lng = 12.9716, 77.5946 # Bangalore approx
        np.random.seed(42)
        
        clusters = [
            (base_lat + 0.02, base_lng + 0.02),
            (base_lat - 0.03, base_lng + 0.01),
            (base_lat + 0.01, base_lng - 0.04)
        ]
        
        incident_types = ["harassment", "robbery", "stalking", "suspicious_activity"]
        
        for center_lat, center_lng in clusters:
            for _ in range(20):
                lat = center_lat + np.random.normal(0, 0.005)
                lng = center_lng + np.random.normal(0, 0.005)
                inc_type = np.random.choice(incident_types)
                
                # Manual timedelta using seconds to avoid issues
                offset_days = np.random.randint(0, 30)
                timestamp = datetime.datetime.utcnow() - datetime.timedelta(days=int(offset_days))
                
                db_inc = models.Incident(
                    user_id=user_id,
                    lat=lat,
                    lng=lng,
                    type=inc_type,
                    timestamp=timestamp
                )
                db.add(db_inc)
        db.commit()

@router.get("/hotspots")
def get_hotspots(db: Session = Depends(get_db)):
    seed_dummy_incidents(db)
    incidents = db.query(models.Incident).all()
    
    if not incidents:
        return {"type": "FeatureCollection", "features": []}
        
    coords = np.array([[inc.lat, inc.lng] for inc in incidents])
    
    n_clusters = min(3, len(coords))
    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    labels = kmeans.fit_predict(coords)
    centers = kmeans.cluster_centers_
    
    features = []
    
    for i, center in enumerate(centers):
        cluster_points = coords[labels == i]
        if len(cluster_points) > 0:
            distances = np.linalg.norm(cluster_points - center, axis=1)
            radius = float(np.max(distances)) if len(distances) > 0 else 0.01
        else:
            radius = 0.01
            
        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [float(center[1]), float(center[0])] 
            },
            "properties": {
                "type": "hotspot_center",
                "risk_level": "high",
                "incident_count": int(np.sum(labels == i)),
                "radius_degrees": float(radius)
            }
        })
        
    for inc in incidents:
        features.append({
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [float(inc.lng), float(inc.lat)]
            },
            "properties": {
                "type": inc.type,
                "timestamp": inc.timestamp.isoformat()
            }
        })
        
    return {
        "type": "FeatureCollection",
        "features": features
    }

@router.post("/sensor/upload")
def upload_sensor_data(sensor_data: dict, db: Session = Depends(get_db)):
    """
    Accepts accelerometer, gyroscope, and GPS payload.
    In a real app, this would be written to a time-series DB or big data lake 
    like BigQuery/InfluxDB for ML training. 
    Here we mock successful ingestion.
    """
    # Ex: { "acc_x": 0.5, "acc_y": 0.1, "acc_z": 9.8, "gyro_x": 0.1, ... }
    return {
        "status": "success", 
        "message": "Sensor data received for latency-free storage",
        "keys_received": list(sensor_data.keys())
    }

@router.post("/report-incident", response_model=schemas.Incident)
def report_incident(payload: schemas.ReportIncidentPayload, db: Session = Depends(get_db)):
    # We use a dummy user for unauthenticated requests for now
    dummy_user = db.query(models.User).first()
    user_id = dummy_user.id if dummy_user else 1

    db_incident = models.Incident(
        user_id=user_id,
        lat=payload.latitude,
        lng=payload.longitude,
        type=payload.incident_type,
        timestamp=payload.timestamp or datetime.datetime.utcnow()
    )
    db.add(db_incident)
    db.commit()
    db.refresh(db_incident)
    return db_incident
