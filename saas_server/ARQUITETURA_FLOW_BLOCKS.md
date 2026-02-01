# ✅ Arquitetura: Flow Editor ↔ flow_blocks ↔ prompt_voz

## 📋 Princípio Fundamental

**O frontend e backend NUNCA atualizam `prompt_voz` diretamente.**
- ✅ Frontend → **Apenas** `flow_blocks` (via APIs)
- ✅ Backend → **Apenas** `flow_blocks` (via Supabase)
- ✅ Banco de Dados → **Trigger automático** atualiza `prompt_voz` quando `flow_blocks` muda

## 🔄 Fluxo de Dados

```
┌─────────────────┐
│  Flow Editor     │
│  (Frontend)      │
└────────┬─────────┘
         │
         │ POST /api/flows/save
         │ PATCH /api/flows/{flow_id}/blocks/{block_key}
         │
         ▼
┌─────────────────┐
│  FastAPI Backend │
│  (flows.py)      │
└────────┬─────────┘
         │
         │ UPDATE/INSERT flow_blocks
         │
         ▼
┌─────────────────┐
│  Supabase        │
│  flow_blocks     │
└────────┬─────────┘
         │
         │ 🔔 TRIGGER automático
         │
         ▼
┌─────────────────┐
│  Supabase        │
│  assistentes     │
│  prompt_voz      │
└─────────────────┘
```

## ✅ Endpoints do Backend

### 1. `POST /api/flows/save`
- **O que faz**: Salva múltiplos blocos em `flow_blocks`
- **O que NÃO faz**: Não atualiza `prompt_voz` diretamente
- **Arquivo**: `saas_server/saas_tools/api/flows.py` (linha 116)
- **Serviço**: `saas_server/saas_tools/services/flow_service.py` (linha 347)

### 2. `PATCH /api/flows/{flow_id}/blocks/{block_key}`
- **O que faz**: Atualiza um único bloco em `flow_blocks`
- **O que NÃO faz**: Não atualiza `prompt_voz` diretamente
- **Arquivo**: `saas_server/saas_tools/api/flows.py` (linha 142)
- **Método**: Usa função RPC `update_flow_block_simple` para performance

### 3. `GET /api/flows/by-assistant/{assistente_id}`
- **O que faz**: Lê `prompt_voz` do assistente (apenas leitura, para criar flow inicial)
- **O que NÃO faz**: Não atualiza `prompt_voz`
- **Arquivo**: `saas_server/saas_tools/api/flows.py` (linha 30)

## 🔔 Trigger no Banco de Dados

O trigger `trigger_sync_prompt_voz_on_block_change` (que você criou) é responsável por:
- ✅ Detectar mudanças em `flow_blocks` (INSERT, UPDATE, DELETE)
- ✅ Atualizar automaticamente `prompt_voz` na tabela `assistentes`
- ✅ Fazer atualização cirúrgica (só muda a parte específica do bloco)

**⚠️ IMPORTANTE**: O trigger deve estar **ATIVO** no banco de dados para que a sincronização funcione.

## 🚫 O Que NÃO Fazer

### ❌ Frontend NÃO deve:
- Chamar APIs que atualizam `prompt_voz` diretamente
- Tentar atualizar `assistentes.prompt_voz` via Supabase client
- Fazer UPDATE direto em `prompt_voz`

### ❌ Backend NÃO deve:
- Fazer `UPDATE assistentes SET prompt_voz = ...` diretamente
- Chamar `client.table("assistentes").update(...)` para atualizar `prompt_voz`
- Criar endpoints que atualizam `prompt_voz` diretamente

## ✅ O Que Fazer

### ✅ Frontend DEVE:
- Usar `POST /api/flows/save` para salvar múltiplos blocos
- Usar `PATCH /api/flows/{flow_id}/blocks/{block_key}` para atualizar um bloco
- Confiar que o trigger vai atualizar `prompt_voz` automaticamente

### ✅ Backend DEVE:
- Atualizar apenas `flow_blocks` via Supabase
- Usar função RPC `update_flow_block_simple` para performance
- Deixar o trigger cuidar da sincronização com `prompt_voz`

## 🔍 Verificação

Para verificar se está tudo correto:

1. **Verificar que não há atualizações diretas a `prompt_voz` no backend**:
   ```bash
   grep -r "prompt_voz.*=" saas_server/saas_tools/
   grep -r "assistentes.*update" saas_server/saas_tools/
   ```
   Resultado esperado: Nenhuma atualização direta encontrada

2. **Verificar que o trigger está ativo**:
   ```sql
   SELECT tgname, tgenabled 
   FROM pg_trigger 
   WHERE tgrelid = 'flow_blocks'::regclass
     AND tgname LIKE '%prompt_voz%';
   ```
   Resultado esperado: Trigger ativo (`tgenabled = 'O'`)

3. **Testar fluxo completo**:
   - Editar um bloco no Flow Editor
   - Verificar que `flow_blocks` foi atualizado
   - Verificar que `prompt_voz` foi atualizado automaticamente pelo trigger

## 📝 Notas Importantes

- O trigger pode causar timeout se for muito pesado. Se isso acontecer, otimize o trigger ou aumente `statement_timeout` no Supabase.
- A função RPC `update_flow_block_simple` é otimizada para evitar timeout.
- O frontend não precisa saber sobre `prompt_voz` - ele só trabalha com `flow_blocks`.
