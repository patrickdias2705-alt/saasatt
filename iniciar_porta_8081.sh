#!/bin/bash
# Script para iniciar o servidor na porta 8081

echo "🛑 FECHANDO PORTAS E LIMPANDO PROCESSOS..."
echo ""

# 1. Matar processos na porta 8081
echo "1️⃣ Fechando porta 8081..."
lsof -ti:8081 | xargs kill -9 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Porta 8081 liberada"
else
    echo "   ℹ️  Porta 8081 já estava livre"
fi

# 2. Matar todos os processos uvicorn na porta 8081
echo "2️⃣ Fechando processos uvicorn na porta 8081..."
pkill -9 -f "uvicorn.*8081" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Processos uvicorn finalizados"
else
    echo "   ℹ️  Nenhum processo uvicorn encontrado"
fi

# 3. Aguardar um pouco para garantir que tudo foi fechado
echo "3️⃣ Aguardando liberação de recursos..."
sleep 2

# 4. Verificar se a porta está livre
echo "4️⃣ Verificando se porta 8081 está livre..."
if lsof -ti:8081 > /dev/null 2>&1; then
    echo "   ⚠️  Porta 8081 ainda está em uso!"
    echo "   Tentando forçar fechamento..."
    lsof -ti:8081 | xargs kill -9 2>/dev/null
    sleep 2
fi

# 5. Navegar para o diretório do servidor
cd "$(dirname "$0")/saas_server" || exit 1

# 6. Verificar se o ambiente virtual existe
if [ ! -d ".venv" ]; then
    echo "❌ Ambiente virtual (.venv) não encontrado!"
    echo "   Execute: python -m venv .venv"
    echo "   Depois: source .venv/bin/activate"
    echo "   Depois: pip install -r requirements.txt"
    exit 1
fi

# 7. Ativar ambiente virtual e iniciar servidor
echo ""
echo "🚀 INICIANDO SISTEMA NA PORTA 8081..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Servidor será iniciado em: http://0.0.0.0:8081"
echo "📍 Flow Editor: http://localhost:8081/flow"
echo "📍 Health Check: http://localhost:8081/health"
echo ""
echo "⚠️  Para parar o servidor, pressione Ctrl+C"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ativar venv e iniciar servidor
source .venv/bin/activate
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8081
