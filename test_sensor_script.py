import urllib.request
import json
import time

url = "http://127.0.0.1:8001/api/sensor/upload"
headers = {
    "Authorization": "Bearer test_token",
    "Content-Type": "application/json"
}

print("Starting HTTP tests...")
for i in range(50):
    payload = {
        "acc_x": 15.5 if i % 2 == 0 else -15.5,
        "acc_y": 10.2 if i % 2 == 0 else -10.2,
        "acc_z": 2.0,
        "gyro_x": 5.0 if i % 2 == 0 else -5.0,
        "gyro_y": 6.1,
        "gyro_z": 1.1,
        "lat": 12.9716,
        "lng": 77.5946
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers, method='POST')
    
    try:
        with urllib.request.urlopen(req) as response:
            result = response.read().decode('utf-8')
            if '"critical_sos_triggered"' in result:
                print(f"BINGO! At frame {i+1}: {result}")
                break
            else:
                print(f"Frame {i+1}: {result}")
    except Exception as e:
        print(f"HTTP Frame {i+1} Failed: {e}")
        try:
            print(e.read().decode('utf-8'))
        except:
            pass
    time.sleep(0.01)

print("Done.")
