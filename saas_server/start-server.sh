#!/bin/bash
# Inicia o servidor Salesdever SaaS na porta 8000
# Execute no Terminal do Mac: ./start-server.sh
# Ou: bash start-server.sh

cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
    echo "❌ Pasta .venv não encontrada. Crie o ambiente: python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
    exit 1
fi

echo "🚀 Iniciando servidor em http://127.0.0.1:8000"
echo "   Pressione Ctrl+C para parar."
echo ""

. .venv/bin/activate
uvicorn main:app --reload --host 127.0.0.1 --port 8000
