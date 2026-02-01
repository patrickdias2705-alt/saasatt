# 🚀 Como Iniciar o Servidor

## Método 1: Usando o Script (Recomendado)

```bash
cd "/Users/patrickdiasparis/Downloads/salesdever_software_main-main 7/saas_server"
./start_server.sh
```

## Método 2: Manualmente

```bash
# 1. Ir para o diretório do servidor
cd "/Users/patrickdiasparis/Downloads/salesdever_software_main-main 7/saas_server"

# 2. Ativar ambiente virtual
source .venv/bin/activate

# 3. Iniciar servidor
python -m uvicorn main:app --host 127.0.0.1 --port 8080 --reload
```

## Verificar se está funcionando

Abra no navegador:
- **Health check:** http://localhost:8080/health
- **Flow Editor:** http://localhost:8080/flow
- **API:** http://localhost:8080/api/flows

## Se houver erros

1. **Erro de importação:** Verifique se todas as dependências estão instaladas:
   ```bash
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Porta já em uso:** Pare o processo que está usando a porta 8080:
   ```bash
   lsof -ti:8080 | xargs kill -9
   ```

3. **Erro de módulo não encontrado:** Ative o ambiente virtual antes de executar:
   ```bash
   source .venv/bin/activate
   ```

## URLs Importantes

- **Servidor:** http://localhost:8080
- **Health Check:** http://localhost:8080/health
- **Flow Editor:** http://localhost:8080/flow?assistente_id=XXX&tenant_id=XXX
- **API Flows:** http://localhost:8080/api/flows
