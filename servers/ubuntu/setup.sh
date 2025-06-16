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
from datetime import datetime
import platform

app = Flask(__name__)

# Configuração do banco de dados
DATABASE = 'iot_data.db'

def get_db():
    db = sqlite3.connect(DATABASE)
    db.row_factory = sqlite3.Row
    return db

def init_db():
    with app.app_context():
        db = get_db()
        db.execute('''
            CREATE TABLE IF NOT EXISTS sensor_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sensor_id TEXT NOT NULL,
                temp REAL NOT NULL,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        db.commit()

@app.route('/api/data', methods=['POST'])
def receive_data():
    try:
        data = request.json
        
        # Validação básica
        if not data or 'sensor_id' not in data or 'temp' not in data:
            return jsonify({"error": "Dados inválidos"}), 400
        
        db = get_db()
        db.execute(
            'INSERT INTO sensor_data (sensor_id, temp) VALUES (?, ?)',
            (data['sensor_id'], data['temp'])
        )
        db.commit()
        
        return jsonify({
            "status": "success",
            "server": platform.system(),
            "received": {
                "sensor_id": data['sensor_id'],
                "temp": data['temp']
            }
        }), 201
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/data', methods=['GET'])
def get_all_data():
    db = get_db()
    cursor = db.execute('SELECT * FROM sensor_data ORDER BY timestamp DESC LIMIT 10')
    data = cursor.fetchall()
    return jsonify([dict(row) for row in data])

@app.route('/api/server-info', methods=['GET'])
def server_info():
    return jsonify({
        "server_os": platform.system(),
        "python_version": platform.python_version(),
        "current_time": datetime.now().isoformat()
    })

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
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