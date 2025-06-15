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
'@ | Out-File -Encoding utf8 -FilePath "$projectDir\server.py"

# Cria atalho na área de trabalho
$shortcutPath = "$env:USERPROFILE\Desktop\Start IoT Server.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "cmd.exe"
$shortcut.Arguments = "/k python `"$projectDir\server.py`""
$shortcut.Save()

Write-Host "Configuração concluída! Execute o servidor pelo atalho na área de trabalho."