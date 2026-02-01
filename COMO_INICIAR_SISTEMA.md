# 🚀 COMO INICIAR O SISTEMA COMPLETO

## ✅ SISTEMA INICIADO!

O servidor foi iniciado em background. Para ver os logs ou parar o servidor, veja abaixo.

## 📋 OPÇÕES PARA INICIAR O SISTEMA

### Opção 1: Script Automático (Recomendado)
```bash
cd /Users/patrickdiasparis/Downloads/salesdever_software_main-main\ 7
./iniciar_sistema_completo.sh
```

Este script:
- ✅ Fecha todas as portas (8000)
- ✅ Limpa processos uvicorn/python
- ✅ Inicia o servidor completo
- ✅ Mostra logs em tempo real

### Opção 2: Manual
```bash
# 1. Fechar processos existentes
lsof -ti:8080 | xargs kill -9 2>/dev/null
pkill -9 -f "uvicorn main:app" 2>/dev/null

# 2. Navegar para o diretório do servidor
cd saas_server

# 3. Ativar ambiente virtual
source .venv/bin/activate

# 4. Iniciar servidor
python -m uvicorn main:app --reload --host 127.0.0.1 --port 8080
```

## 🔍 VERIFICAR SE ESTÁ RODANDO

```bash
# Health check
curl http://127.0.0.1:8080/health

# Ver processos
ps aux | grep uvicorn

# Ver porta 8080
lsof -i:8080
```

## 🛑 PARAR O SERVIDOR

### Se rodando em foreground (terminal):
- Pressione `Ctrl+C`

### Se rodando em background:
```bash
# Matar por porta
lsof -ti:8080 | xargs kill -9

# Ou matar por processo
pkill -9 -f "uvicorn main:app"
```

## 📍 URLs DO SISTEMA

- **Servidor:** http://127.0.0.1:8080
- **Health Check:** http://127.0.0.1:8080/health
- **Flow Editor:** http://127.0.0.1:8080/flow?assistente_id=...&tenant_id=...
- **Página Principal:** http://127.0.0.1:8080/
- **API Flows:** http://127.0.0.1:8080/api/flows
- **API Assistants:** http://127.0.0.1:8080/api/assistants

## ✅ O QUE ESTÁ INCLUÍDO NO SISTEMA

### APIs Configuradas:
- ✅ `/api/flows/*` - Flow Editor (8 endpoints)
- ✅ `/api/assistants/*` - Assistentes (4 endpoints)
- ✅ `/api/tools/*` - Tools Manager
- ✅ `/api/dashboard/*` - Dashboard

### Interfaces:
- ✅ `/flow` - Flow Editor (React/Vite)
- ✅ `/menu_principal/*` - Interface estática do SaaS
- ✅ `/static/*` - Arquivos estáticos

## 🐛 PROBLEMAS COMUNS

### Porta 8080 já está em uso
```bash
lsof -ti:8080 | xargs kill -9
```

### Ambiente virtual não encontrado
```bash
cd saas_server
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Erro ao importar módulos
```bash
cd saas_server
source .venv/bin/activate
pip install -r requirements.txt
```

### Servidor não responde
1. Verifique se está rodando: `ps aux | grep uvicorn`
2. Verifique logs no terminal
3. Tente reiniciar: `./iniciar_sistema_completo.sh`

## 📝 LOGS

Os logs do servidor aparecem no terminal onde você executou o comando.

Para ver logs em tempo real se rodando em background:
```bash
tail -f /Users/patrickdiasparis/.cursor/projects/Users-patrickdiasparis-Downloads-salesdever-software-main-main-7/terminals/*.txt
```
