import requests
import random
import time

def simulate_distress():
    url = "http://localhost:8001/api/sensor/upload"
    headers = {
        "Authorization": "Bearer test_token"
    }
    
    print("Starting ML Distress Simulation...")
    print("Sending 50 arrays of high-variance accelerometer data to trigger the auto-SOS protocol...")
    
    for i in range(50):
        # Simulate extreme distress (falling, rapid shaking)
        payload = {
            "acc_x": random.uniform(-15.0, 15.0),
            "acc_y": random.uniform(-15.0, 15.0),
            "acc_z": random.uniform(-15.0, 15.0),
            "gyro_x": random.uniform(-15.0, 15.0),
            "gyro_y": random.uniform(-15.0, 15.0),
            "gyro_z": random.uniform(-15.0, 15.0),
            "lat": 12.9716,
            "lng": 77.5946
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            if response.status_code == 200:
                data = response.json()
                status = data.get("status")
                
                if status == "critical_sos_triggered":
                    print(f"\n[SUCCESS] SOS Triggered at Window {i+1}!")
                    print(f"ML Probability: {data.get('probability'):.4f}")
                    print(f"Message: {data.get('message')}")
                    return
                else:
                    print(f"[{i+1}/50] Buffer filling... Status: {status}")
            else:
                print(f"Error {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"Connection failed: {e}. Is the backend running?")
            break
            
        # tiny delay to avoid overwhelming the loop instantly but enough to see output
        time.sleep(0.01)

if __name__ == "__main__":
    simulate_distress()
