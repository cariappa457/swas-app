from fastapi import APIRouter, Depends, BackgroundTasks
from sqlalchemy.orm import Session
import models, schemas
from database import get_db
import datetime
import numpy as np
from sklearn.cluster import KMeans
import logging
from dependencies import get_current_user
from ml_inference import lstm_predictor

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

logger = logging.getLogger(__name__)

# In-memory buffer for sliding sensor windows per user
# Shape: dict mapping user_id -> List(shape 50x6)
_sensor_buffers = {}

@router.post("/sensor/upload")
def upload_sensor_data(
    sensor_data: dict, 
    background_tasks: BackgroundTasks,
    user: models.User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    """
    Accepts live accelerometer/gyroscope readings.
    Buffers incoming data into a sliding window (size 50).
    Runs inference via the MockLSTMPredictor.
    If anomaly detected -> Auto trigger SOS.
    """
    uid = user.id
    if uid not in _sensor_buffers:
        _sensor_buffers[uid] = []
        
    # Extract the 6 features expected by the LSTM
    features = [
        float(sensor_data.get("acc_x", 0.0)),
        float(sensor_data.get("acc_y", 0.0)),
        float(sensor_data.get("acc_z", 0.0)),
        float(sensor_data.get("gyro_x", 0.0)),
        float(sensor_data.get("gyro_y", 0.0)),
        float(sensor_data.get("gyro_z", 0.0)),
    ]
    _sensor_buffers[uid].append(features)
    
    # Process when the window reaches 50 timesteps
    if len(_sensor_buffers[uid]) >= 50:
        window = _sensor_buffers[uid][-50:]
        
        # Shift buffer by 25 to provide a 50% overlap for continuous detection
        _sensor_buffers[uid] = _sensor_buffers[uid][25:]
        
        prob = lstm_predictor.predict_anomaly(window)
        
        # If probability indicates severe distress (shaking/falling)
        if prob > 0.8:
            logger.warning(f"ML DETECTED ANOMALY (prob={prob:.2f}) FOR USER {uid}. AUTO-TRIGGERING SOS!")
            
            # Fetch location if available in telemetry
            lat = float(sensor_data.get("lat", 0.0))
            lng = float(sensor_data.get("lng", 0.0))
            
            payload = schemas.EmergencyCallTrigger(
                trigger_type="auto_ml_distress",
                lat=lat,
                lng=lng
            )
            
            # Trigger the SOS flow via the existing logic
            from routers.sos import trigger_emergency_call
            try:
                # Invoking the SOS router directly runs DB updates and Twilio background tasks
                trigger_emergency_call(payload, background_tasks, user, db)
                return {
                    "status": "critical_sos_triggered",
                    "probability": prob,
                    "message": "Automated SOS protocol initiated successfully."
                }
            except Exception as e:
                # Ignore 429 too many requests (cooldown) from raising 500
                logger.warning(f"Auto SOS trigger ignored or failed: {str(e)}")
                
        return {"status": "processed", "probability": prob, "buffered": len(_sensor_buffers[uid])}
        
    return {
        "status": "buffering", 
        "buffered": len(_sensor_buffers[uid]),
        "required": 50
    }

@router.post("/report-incident", response_model=schemas.Incident)
def report_incident(payload: schemas.ReportIncidentPayload, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    db_incident = models.Incident(
        user_id=user.id,
        lat=payload.latitude,
        lng=payload.longitude,
        type=payload.incident_type,
        timestamp=payload.timestamp or datetime.datetime.utcnow()
    )
    db.add(db_incident)
    db.commit()
    db.refresh(db_incident)
    return db_incident
