from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from main import app
from database import Base, get_db

SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

def test_read_main():
    response = client.get("/")
    assert response.status_code == 200
    assert "SWSAS Backend" in response.json()["message"]

def test_register_user():
    response = client.post(
        "/api/register",
        json={
            "firebase_uid": "test_uid_123",
            "email": "testuser@example.com",
            "phone": "+1234567890",
            "name": "Test User",
            "age": 25,
            "auto_distress_enabled": True,
            "mic_access_enabled": False,
            "sensor_monitoring_enabled": True
        },
    )
    assert response.status_code == 201
    assert response.json()["email"] == "testuser@example.com"
    assert "id" in response.json()

def test_trigger_sos():
    # Trigger SOS for user created in previous test (assuming id=1)
    response = client.post(
        "/api/sos/trigger?user_id=1",
        json={
            "trigger_type": "manual",
            "lat": 12.9716,
            "lng": 77.5946,
            "audio_url": None
        },
    )
    if response.status_code == 200:
        assert response.json()["status"] == "active"
        assert response.json()["lat"] == 12.9716
