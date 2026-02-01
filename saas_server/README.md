# SaaS Server (único domínio, sem iframe)

Este servidor roda **tudo no mesmo host**:

- UI do SaaS estático (`/` e `/menu_principal/...`)
- Tools manager (vapi-tools-manager) em `/tools/*`
- APIs REST do tools manager em `/api/*`
- (próximo) Flow editor em `/flow/*` (build do Vite)

## Rodar

```bash
cd "saas_server"
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8080
```

Abra:

- `http://localhost:8080/menu_principal/assistentes/assistente.html`
- `http://localhost:8080/tools/gerenciar-tools`

