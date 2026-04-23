import requests
import random
import time

def simulate_distress():
    # Update this to 8000 to match your current backend port
    url = "http://127.0.0.1:8000/api/sensor/upload"
    headers = {
        "Authorization": "Bearer test_token"
    }
    
    print("===============================================")
    print(" SWSAS ML Distress Simulation (DSVA Pattern)   ")
    print("===============================================")
    
    # We will send 50 samples. Samples 1-40 will be erratic (The Shake/Impact)
    # Samples 41-50 will be zero movement (The Fall/Silence)
    
    for i in range(50):
        if i < 40:
            # High intensity shake/impact pattern
            acc_val = random.uniform(15.0, 30.0) 
        else:
            # Dead stillness pattern (Following the fall)
            acc_val = random.uniform(0.0, 0.2)

        payload = {
            "acc_x": acc_val,
            "acc_y": acc_val,
            "acc_z": acc_val,
            "gyro_x": 0.0,
            "gyro_y": 0.0,
            "gyro_z": 0.0,
            "lat": 12.9716,
            "lng": 77.5946
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            if response.status_code == 200:
                data = response.json()
                status = data.get("status")
                
                if status == "critical_sos_triggered":
                    print(f"\n[🚨 ALERT] ML SOS TRIGGERED at Window {i+1}!")
                    print(f"Algorithm: DSVA (Dynamic Signal Variance Analysis)")
                    print(f"ML Probability: {data.get('probability', 0.0):.4f}")
                    return
                else:
                    print(f"[{i+1}/50] Signal processing... Intensity: {acc_val:.1f}")
            else:
                print(f"Error {response.status_code}: {response.text}")
                
        except Exception as e:
            print(f"Connection failed: {e}. Is the backend running?")
            break
            
        time.sleep(0.01)

if __name__ == "__main__":
    simulate_distress()
