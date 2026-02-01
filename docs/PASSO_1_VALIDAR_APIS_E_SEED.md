# Passo 1: Validar APIs e seed (ordem de implementação)

**Este arquivo é documentação (.md). Não rode este arquivo no SQL Editor do Supabase.**

---

## Como fazer (resumido)

### A) Subir o servidor

1. Abra o **Terminal** (Mac) ou o terminal do Cursor.
2. Vá até a pasta do servidor:
   ```bash
   cd /Users/patrickdiasparis/Downloads/salesdever_software_main-main\ 7/saas_server
   ```
   (Ou, se você já está na pasta do projeto: `cd saas_server`)
3. Rode:
   ```bash
   ./start-server.sh
   ```
4. Deixe essa janela aberta (o servidor fica rodando). Deve aparecer algo como: `Uvicorn running on http://127.0.0.1:8000`.

### B) Testar as APIs

Com o servidor rodando, você pode:

**Opção 1 – No navegador**  
Abra estes endereços (um de cada vez):

- http://127.0.0.1:8000/api/flows?tenant_id=tenant-teste-001  
  → Deve mostrar uma lista com 3 flows (JSON).
- http://127.0.0.1:8000/api/flows/by-assistant/assistente-teste-001/prompt  
  → Deve mostrar um JSON com o campo `"prompt"` e o texto montado.

**Opção 2 – No Terminal** (em outra aba/janela do terminal):

```bash
curl -s "http://127.0.0.1:8000/api/flows?tenant_id=tenant-teste-001"
curl -s "http://127.0.0.1:8000/api/flows/by-assistant/assistente-teste-001/prompt"
```

Se aparecer JSON (e não erro de conexão), o Passo 1 está ok.

---

## 1. Rodar o SQL no Supabase

No **SQL Editor do Supabase** execute **somente arquivos .sql**.

- **Se as tabelas de flow ainda não existem:** execute primeiro **`saas_server/supabase/flow_editor_tables.sql`** (cria `flows`, `flow_blocks`, `flow_routes`, `flow_versions` + RLS + triggers).
- **Se as tabelas já existem (você já criou):** pule o item acima.
- **Sempre:** execute **`saas_server/supabase/flow_editor_seed_test.sql`** (insere 1 tenant com 3 assistentes e 3 flows de teste).

Confira se não houve erro. Opcional: em **Table Editor**, veja as tabelas `flows`, `flow_blocks`, `flow_routes`.

---

## 2. Configurar e subir o servidor

1. Na pasta `saas_server`, confira o `.env` (ou `.env.example`):  
   `SUPABASE_URL` e `SUPABASE_KEY` (service role ou anon) apontando para o mesmo projeto onde rodou o SQL.
2. Subir o backend:
   ```bash
   cd saas_server
   ./start-server.sh
   ```
   Servidor em **http://127.0.0.1:8000**.

---

## 3. Testar as APIs

Use a base **http://127.0.0.1:8000**. Exemplos com `curl`:

**Listar flows do tenant (deve devolver 3 flows):**
```bash
curl -s "http://127.0.0.1:8000/api/flows?tenant_id=tenant-teste-001"
```

**Flow completo do assistente 1 (flow + blocks + routes):**
```bash
curl -s "http://127.0.0.1:8000/api/flows/by-assistant/assistente-teste-001?tenant_id=tenant-teste-001"
```

**Prompt montado do assistente 1 (para a IA de voz):**
```bash
curl -s "http://127.0.0.1:8000/api/flows/by-assistant/assistente-teste-001/prompt"
```

**Prompt por flow_id (mesmo resultado do assistente 1):**
```bash
curl -s "http://127.0.0.1:8000/api/flows/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11/prompt"
```

**Flow completo por flow_id:**
```bash
curl -s "http://127.0.0.1:8000/api/flows/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
```

Se todos retornarem 200 e os JSONs fizerem sentido (lista de flows, objeto com `flow`/`blocks`/`routes`, objeto com `prompt`), o **Passo 1** está ok.

---

## 4. Próximo passo

Depois de validar: **Passo 2** = integrar o app do Flow Editor (iframe em `/flow`) com essas APIs: carregar por `assistente_id`/`tenant_id` e salvar com `POST /api/flows/save`.
