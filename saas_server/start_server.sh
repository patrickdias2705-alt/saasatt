#!/bin/bash
cd "$(dirname "$0")"

# Ativar ambiente virtual se existir
if [ -d ".venv" ]; then
    echo "✅ Ativando ambiente virtual..."
    source .venv/bin/activate
elif [ -d "venv" ]; then
    echo "✅ Ativando ambiente virtual..."
    source venv/bin/activate
fi

# Verificar se FastAPI está instalado
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "⚠️ FastAPI não encontrado. Instalando dependências..."
    pip install -q fastapi uvicorn python-multipart python-dotenv supabase pydantic aiofiles
fi

echo "🚀 Iniciando servidor na porta 8081..."
echo "📍 Acesse: http://localhost:8081"
echo "📍 Health check: http://localhost:8081/health"
echo ""
python3 -m uvicorn main:app --host 127.0.0.1 --port 8081 --reload
