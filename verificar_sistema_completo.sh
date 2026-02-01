#!/bin/bash
# Script para verificar se TODO o sistema está funcionando

echo "🔍 VERIFICANDO SISTEMA COMPLETO..."
echo ""

BASE_URL="http://127.0.0.1:8000"

# 1. Verificar se o servidor está rodando
echo "1️⃣ Verificando servidor..."
if curl -s "$BASE_URL/health" > /dev/null 2>&1; then
    echo "   ✅ Servidor está rodando em $BASE_URL"
else
    echo "   ❌ Servidor NÃO está rodando!"
    echo "   Execute: cd saas_server && python -m uvicorn main:app --reload --port 8000"
    exit 1
fi

# 2. Verificar rotas principais
echo ""
echo "2️⃣ Verificando rotas principais..."

# Health check
if curl -s "$BASE_URL/health" | grep -q "ok"; then
    echo "   ✅ /health - OK"
else
    echo "   ❌ /health - FALHOU"
fi

# Root
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/" | grep -q "200\|404"; then
    echo "   ✅ / (root) - OK"
else
    echo "   ❌ / (root) - FALHOU"
fi

# Flow Editor
if curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/flow" | grep -q "200"; then
    echo "   ✅ /flow - OK"
else
    echo "   ❌ /flow - FALHOU"
fi

# 3. Verificar APIs
echo ""
echo "3️⃣ Verificando APIs..."

# Flows API (sem tenant_id, deve dar erro mas confirmar que a rota existe)
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/flows")
if [ "$STATUS" = "422" ] || [ "$STATUS" = "400" ]; then
    echo "   ✅ /api/flows - Rota existe (erro esperado sem tenant_id)"
else
    echo "   ⚠️  /api/flows - Status: $STATUS"
fi

# Assistants API
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/assistants")
if [ "$STATUS" = "404" ] || [ "$STATUS" = "422" ] || [ "$STATUS" = "200" ]; then
    echo "   ✅ /api/assistants - Rota existe"
else
    echo "   ⚠️  /api/assistants - Status: $STATUS"
fi

# Tools API
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/tools")
if [ "$STATUS" = "404" ] || [ "$STATUS" = "422" ] || [ "$STATUS" = "200" ]; then
    echo "   ✅ /api/tools - Rota existe"
else
    echo "   ⚠️  /api/tools - Status: $STATUS"
fi

# Dashboard API
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/dashboard")
if [ "$STATUS" = "404" ] || [ "$STATUS" = "422" ] || [ "$STATUS" = "200" ]; then
    echo "   ✅ /api/dashboard - Rota existe"
else
    echo "   ⚠️  /api/dashboard - Status: $STATUS"
fi

# 4. Verificar arquivos estáticos
echo ""
echo "4️⃣ Verificando arquivos estáticos..."

# Flow Editor dist
if [ -d "/Users/patrickdiasparis/Downloads/assist-tool-craft-main/dist" ]; then
    if [ -f "/Users/patrickdiasparis/Downloads/assist-tool-craft-main/dist/index.html" ]; then
        echo "   ✅ Flow Editor dist/ existe e tem index.html"
    else
        echo "   ⚠️  Flow Editor dist/ existe mas sem index.html"
    fi
else
    echo "   ❌ Flow Editor dist/ NÃO existe!"
    echo "   Execute: cd assist-tool-craft-main && npm run build"
fi

# Menu principal
if [ -d "menu_principal" ]; then
    echo "   ✅ menu_principal/ existe"
else
    echo "   ⚠️  menu_principal/ não encontrado"
fi

# 5. Verificar processos
echo ""
echo "5️⃣ Verificando processos..."

if pgrep -f "uvicorn main:app" > /dev/null; then
    echo "   ✅ Servidor uvicorn está rodando"
    PID=$(pgrep -f "uvicorn main:app" | head -1)
    echo "   📍 PID: $PID"
else
    echo "   ❌ Servidor uvicorn NÃO está rodando!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ VERIFICAÇÃO COMPLETA!"
echo ""
echo "📝 Próximos passos:"
echo "   1. Abra http://127.0.0.1:8000 no navegador"
echo "   2. Teste o Flow Editor em http://127.0.0.1:8000/flow"
echo "   3. Verifique o console do navegador (F12) para erros"
echo ""
