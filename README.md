# Projeto IoT com Máquinas Virtuais

Implementação de um sistema IoT básico usando múltiplos servidores em VMs (Ubuntu, Debian e Windows 10) com monitoramento de desempenho comparativo.

## 📋 Requisitos

- Hyper-V ativado (Windows Pro/Enterprise)
- ISOs:
  - Ubuntu 24.04
  - Debian 12
  - Windows 10
- PowerShell 5.1+
- Chocolatey (para instalação de dependências no Windows)

## 🚀 Configuração

### 1. Preparação das VMs

Crie 3 máquinas virtuais no Hyper-V:

| VM        | Sistema Operacional | Configuração           |
|-----------|---------------------|------------------------|
| vm-ubuntu | Ubuntu 24.04        | 2 vCPU, 8GB RAM, 200GB |
| vm-debian | Debian 12           | 2 vCPU, 8GB RAM, 200GB |
| vm-win10  | Windows 10          | 2 vCPU, 8GB RAM, 200GB |

### 2. Configuração dos Servidores

Para cada VM:

#### Linux (Ubuntu/Debian):
```bash
# Execute o script de setup
chmod +x setup.sh
sudo ./setup.sh