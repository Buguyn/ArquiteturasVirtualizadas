<#
.SYNOPSIS
    Configura o servidor IoT no Windows 10
#>

# Instala Python se necessário
if (-not (Test-Path "C:\Python310\python.exe")) {
    Write-Host "Instalando Python..."
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.10.5/python-3.10.5-amd64.exe" -OutFile "$env:TEMP\python-installer.exe"
    Start-Process -Wait -FilePath "$env:TEMP\python-installer.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1"
}

# Instala Flask
python -m pip install --upgrade pip
pip install flask

# Cria diretório do projeto
$projectDir = "$env:USERPROFILE\iot-server"
if (-not (Test-Path $projectDir)) {
    New-Item -ItemType Directory -Path $projectDir
}

# Cria arquivo do servidor
@'
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
'@ | Out-File -Encoding utf8 -FilePath "$projectDir\server.py"

# Cria atalho na área de trabalho
$shortcutPath = "$env:USERPROFILE\Desktop\Start IoT Server.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "cmd.exe"
$shortcut.Arguments = "/k python `"$projectDir\server.py`""
$shortcut.Save()

Write-Host "Configuração concluída! Execute o servidor pelo atalho na área de trabalho."