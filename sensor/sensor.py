
## 📄 **sensor.py** (Para o Host Windows)

python
import requests
import random
import time
from datetime import datetime

# Configuração
SERVERS = {
    "Ubuntu": "http://192.168.1.100:5000/api/data",
    "Debian": "http://192.168.1.101:5000/api/data",
    "Windows10": "http://192.168.1.102:5000/api/data"
}

SENSOR_ID = "sensor-host01"
INTERVAL = 5  # segundos

def send_data(server_name, url):
    try:
        temp = round(random.uniform(20.0, 30.0), 2)
        payload = {
            "sensor_id": SENSOR_ID,
            "temp": temp
        }
        
        start_time = time.time()
        response = requests.post(url, json=payload, timeout=3)
        latency = round((time.time() - start_time) * 1000, 2)
        
        print(f"[{datetime.now().isoformat()}] {server_name}:")
        print(f"  → Enviado: {temp}°C | Status: {response.status_code}")
        print(f"  → Latência: {latency}ms")
        print(f"  → Resposta: {response.json()}")
        
    except Exception as e:
        print(f"[{datetime.now().isoformat()}] Erro em {server_name}: {str(e)}")

if __name__ == '__main__':
    print(f"Iniciando sensor {SENSOR_ID}...")
    try:
        while True:
            for name, url in SERVERS.items():
                send_data(name, url)
            print("-" * 50)
            time.sleep(INTERVAL)
    except KeyboardInterrupt:
        print("\nSensor encerrado.")