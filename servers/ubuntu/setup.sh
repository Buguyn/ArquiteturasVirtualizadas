#!/bin/bash
# Atualiza sistema e instala dependências
sudo apt update
sudo apt upgrade -y
sudo apt install -y python3 python3-pip sqlite3

# Instala Flask
pip3 install flask

# Cria diretório do projeto
mkdir -p ~/iot-server
cd ~/iot-server

# Cria arquivo do servidor
cat > server.py << 'EOF'
from flask import Flask, request, jsonify
import sqlite3

app = Flask(__name__)
conn = sqlite3.connect('iot_data.db', check_same_thread=False)
cursor = conn.cursor()
cursor.execute('''CREATE TABLE IF NOT EXISTS sensor_data
                  (id INTEGER PRIMARY KEY AUTOINCREMENT,
                   sensor_id TEXT,
                   temp REAL,
                   timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')

@app.route('/api/data', methods=['POST'])
def receive_data():
    data = request.json
    cursor.execute("INSERT INTO sensor_data (sensor_id, temp) VALUES (?, ?)",
                   (data['sensor_id'], data['temp']))
    conn.commit()
    return jsonify({"status": "success"}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

# Dá permissão de execução
chmod +x server.py

# Instala o serviço (opcional)
cat > iot-server.service << EOF
[Unit]
Description=IoT Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/\$USER/iot-server/server.py
WorkingDirectory=/home/\$USER/iot-server
Restart=always
User=\$USER

[Install]
WantedBy=multi-user.target
EOF

sudo mv iot-server.service /etc/systemd/system/
sudo systemctl enable iot-server.service
sudo systemctl start iot-server.service

echo "Servidor configurado com sucesso! Acesse em: http://$(hostname -I | awk '{print $1}'):5000"