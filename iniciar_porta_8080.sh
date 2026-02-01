#!/bin/bash
# Script rápido para iniciar na porta 8080

echo "🛑 Fechando processos na porta 8080..."
lsof -ti:8080 | xargs kill -9 2>/dev/null
pkill -9 -f "uvicorn.*8080" 2>/dev/null
sleep 2

echo "🚀 Iniciando servidor na porta 8080..."
cd "$(dirname "$0")/saas_server"
source .venv/bin/activate
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8080
