# Flow Editor – Integração com IA de Voz (VAPI)

O prompt final do agente é montado a partir do **flow** (tabelas `flows`, `flow_blocks`, `flow_routes`) e pode ser consumido pela IA de voz ao iniciar a ligação.

---

## Separação por tenant (um cliente = N assistentes)

- **tenant_id** = um cliente. Cada cliente (tenant) tem seus próprios assistentes e flows; um tenant não vê dados de outro.
- **Um tenant tem N assistentes** (cada um com `assistente_id` na tabela de assistentes, todos com o mesmo `tenant_id`). Ex.: o cliente X tem 2 ou 3 assistentes (vendas, suporte, etc.).
- **Cada assistente tem no máximo um flow** (em `flows`, `assistente_id` aponta para esse assistente; `flow_id` é o flow dele).
- **Listar flows do cliente:** `GET /api/flows?tenant_id=<tenant_id>` — devolve só os flows daquele tenant (ou seja, dos assistentes daquele cliente).
- **Editor:** ao abrir “Editar Assistente”, o front deve enviar **tenant_id** (do cliente logado) e **assistente_id** (do assistente escolhido). O flow carregado/criado é sempre do mesmo tenant; assim cada cliente só edita os assistentes dele.

Resumo: **tenant_id** separa os clientes; dentro de um tenant ficam **todos os assistentes** desse cliente; cada assistente tem **um** flow e **um** prompt (o que “vai mexer” no editor).

---

## Qual assistente → qual prompt “vai mexer”

Os assistentes são os da **tabela de assistentes** do Supabase (schema com `assistente_id`, `tenant_id`, `name`, `prompt_voz`, `prompt_whats`, etc.). Cada linha = um assistente identificado por `assistente_id`.

- **Cada assistente** pode ter **um flow** vinculado: na tabela `flows` o campo `assistente_id` aponta para o `assistente_id` desse assistente.
- O prompt que **o Flow Editor mexe** é exatamente o que é **montado a partir desse flow** (blocos + rotas + prompt_base). Esse é o prompt que a IA de voz deve usar.
- Resumo:
  - **Quem:** assistentes da tabela (identificados por `assistente_id`).
  - **O que muda:** o flow vinculado a esse `assistente_id` (blocos, rotas, prompt_base no Flow Editor).
  - **Qual prompt “vai mexer”:** o texto retornado por **GET /api/flows/by-assistant/{assistente_id}/prompt** — esse é o prompt que deve ser usado na ligação (equivalente ao que hoje pode estar em `prompt_voz`; se quiser, pode passar a usar esse endpoint como fonte da verdade e opcionalmente sincronizar para `prompt_voz` ao salvar o flow).

## Endpoints para obter o prompt

### Por `flow_id`

Quando você já tem o ID do flow (por exemplo, após `GET /api/flows/by-assistant/{assistente_id}`):

- **GET** `/api/flows/{flow_id}/prompt`
- **Resposta:** `{ "prompt": "<texto montado>" }`
- **404** se o flow não existir.

### Por `assistente_id`

Quando a IA de voz identifica o assistente pelo ID (recomendado):

- **GET** `/api/flows/by-assistant/{assistente_id}/prompt`
- **Resposta:** `{ "prompt": "<texto montado>", "flow_id": "<uuid>" }`
- **404** se não houver flow vinculado ao assistente.

## Uso na IA de voz

1. Ao iniciar a ligação, o sistema de voz (ex.: VAPI) deve saber o `assistente_id` do agente.
2. Chamar **GET** `/api/flows/by-assistant/{assistente_id}/prompt` (base URL do SaaS, ex. `https://seu-dominio/api/flows/by-assistant/...`).
3. Enviar o campo `prompt` da resposta como instrução do agente para a IA de voz.

O texto retornado inclui o cabeçalho do flow, o `prompt_base` e a seção **FLUXO DA CONVERSA** com todos os blocos (primeira mensagem, mensagens, aguardar, caminhos, ferramenta, encerrar) formatados para o modelo.
