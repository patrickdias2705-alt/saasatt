#!/bin/bash
# Script para fechar portas, limpar processos e iniciar o sistema completo

echo "🛑 FECHANDO PORTAS E LIMPANDO PROCESSOS..."
echo ""

# 1. Matar processos na porta 8080
echo "1️⃣ Fechando porta 8080..."
lsof -ti:8080 | xargs kill -9 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Porta 8080 liberada"
else
    echo "   ℹ️  Porta 8080 já estava livre"
fi

# 2. Matar todos os processos uvicorn
echo "2️⃣ Fechando processos uvicorn..."
pkill -9 -f "uvicorn main:app" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Processos uvicorn finalizados"
else
    echo "   ℹ️  Nenhum processo uvicorn encontrado"
fi

# 3. Matar processos Python relacionados ao servidor
echo "3️⃣ Limpando processos Python do servidor..."
pkill -9 -f "python.*main:app" 2>/dev/null
pkill -9 -f "python.*uvicorn" 2>/dev/null
echo "   ✅ Processos Python limpos"

# 4. Aguardar um pouco para garantir que tudo foi fechado
echo "4️⃣ Aguardando liberação de recursos..."
sleep 2

# 5. Verificar se a porta está livre
echo "5️⃣ Verificando se porta 8080 está livre..."
if lsof -ti:8080 > /dev/null 2>&1; then
    echo "   ⚠️  Porta 8080 ainda está em uso!"
    echo "   Tentando forçar fechamento..."
    lsof -ti:8080 | xargs kill -9 2>/dev/null
    sleep 2
fi

# 6. Navegar para o diretório do servidor
cd "$(dirname "$0")/saas_server" || exit 1

# 7. Verificar se o ambiente virtual existe
if [ ! -d ".venv" ]; then
    echo "❌ Ambiente virtual (.venv) não encontrado!"
    echo "   Execute: python -m venv .venv"
    exit 1
fi

# 8. Ativar ambiente virtual e iniciar servidor
echo ""
echo "🚀 INICIANDO SISTEMA COMPLETO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Servidor será iniciado em: http://127.0.0.1:8080"
echo "📍 Flow Editor: http://127.0.0.1:8080/flow"
echo "📍 Health Check: http://127.0.0.1:8080/health"
echo ""
echo "⚠️  Para parar o servidor, pressione Ctrl+C"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ativar venv e iniciar servidor
source .venv/bin/activate
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8080
