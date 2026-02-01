# ✅ Configuração Final: Flow Editor ↔ flow_blocks

## 🎯 Objetivo

Garantir que o Flow Editor se comunique **APENAS** com a tabela `flow_blocks`, e que o trigger no banco de dados cuide automaticamente da sincronização com `prompt_voz`.

## ✅ Status Atual

### Backend (Python/FastAPI)
- ✅ `POST /api/flows/save` → Atualiza apenas `flow_blocks`
- ✅ `PATCH /api/flows/{flow_id}/blocks/{block_key}` → Atualiza apenas `flow_blocks`
- ✅ Nenhuma atualização direta a `prompt_voz` no código Python
- ✅ Usa função RPC `update_flow_block_simple` para performance

### Banco de Dados
- ✅ Trigger `trigger_sync_prompt_voz_on_block_change` deve estar **ATIVO**
- ✅ Função RPC `update_flow_block_simple` criada e otimizada
- ✅ Trigger detecta mudanças em `flow_blocks` e atualiza `prompt_voz` automaticamente

### Frontend
- ⚠️ **Verificar**: Frontend deve usar apenas:
  - `POST /api/flows/save` (para salvar múltiplos blocos)
  - `PATCH /api/flows/{flow_id}/blocks/{block_key}` (para atualizar um bloco)
- ⚠️ **NÃO deve**: Tentar atualizar `prompt_voz` diretamente

## 🔧 Verificações Necessárias

### 1. Verificar Trigger no Banco

Execute no Supabase SQL Editor:

```sql
-- Verificar se o trigger está ativo
SELECT 
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'O' THEN '✅ ATIVO'
    WHEN tgenabled = 'D' THEN '❌ DESABILITADO'
    ELSE 'Status: ' || tgenabled
  END as status
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass
  AND tgname LIKE '%prompt_voz%';
```

**Resultado esperado**: Trigger ativo (`tgenabled = 'O'`)

### 2. Verificar Função RPC

```sql
-- Verificar se a função RPC existe
SELECT 
  proname as nome_funcao,
  pg_get_function_arguments(oid) as argumentos
FROM pg_proc 
WHERE proname = 'update_flow_block_simple';
```

**Resultado esperado**: Função existe com os parâmetros corretos

### 3. Testar Fluxo Completo

1. **Editar um bloco no Flow Editor**
   - Frontend chama `PATCH /api/flows/{flow_id}/blocks/{block_key}`
   - Backend atualiza `flow_blocks`
   - Trigger atualiza `prompt_voz` automaticamente

2. **Verificar no banco**:
   ```sql
   -- Verificar que flow_blocks foi atualizado
   SELECT block_key, content, updated_at 
   FROM flow_blocks 
   WHERE block_key = 'ENC001'  -- Substitua pelo bloco que você editou
   ORDER BY updated_at DESC 
   LIMIT 1;
   
   -- Verificar que prompt_voz foi atualizado pelo trigger
   SELECT 
     id,
     substring(prompt_voz, position('ENC001' IN prompt_voz), 200) as secao_atualizada
   FROM assistentes 
   WHERE id = 'SEU_ASSISTENTE_ID';  -- Substitua pelo ID do seu assistente
   ```

## 🚨 Problemas Comuns

### Problema: Timeout ao salvar blocos

**Causa**: Trigger muito pesado ou `statement_timeout` muito baixo

**Solução**:
1. Otimizar o trigger (reduzir operações pesadas)
2. Aumentar `statement_timeout` no Supabase:
   ```sql
   SET statement_timeout = '30s';  -- Aumentar de 10s para 30s
   ```

### Problema: `prompt_voz` não está sendo atualizado

**Causa**: Trigger desabilitado ou não existe

**Solução**:
1. Verificar se o trigger existe e está ativo (ver SQL acima)
2. Se não existir, criar o trigger que você desenvolveu
3. Se estiver desabilitado, habilitar:
   ```sql
   ALTER TABLE flow_blocks ENABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
   ```

### Problema: Frontend tentando atualizar `prompt_voz` diretamente

**Causa**: Código do frontend fazendo UPDATE direto em `prompt_voz`

**Solução**:
1. Remover qualquer código que atualize `prompt_voz` diretamente
2. Garantir que o frontend use apenas:
   - `POST /api/flows/save`
   - `PATCH /api/flows/{flow_id}/blocks/{block_key}`

## 📝 Checklist Final

- [ ] Trigger `trigger_sync_prompt_voz_on_block_change` está **ATIVO** no banco
- [ ] Função RPC `update_flow_block_simple` existe e está funcionando
- [ ] Backend não atualiza `prompt_voz` diretamente (verificado ✅)
- [ ] Frontend usa apenas APIs de `flow_blocks` (verificar no código do frontend)
- [ ] Teste completo: Editar bloco → Verificar `flow_blocks` → Verificar `prompt_voz`

## 🎉 Resultado Esperado

Quando você editar um bloco no Flow Editor:
1. ✅ Frontend chama API de `flow_blocks`
2. ✅ Backend atualiza `flow_blocks` no banco
3. ✅ Trigger detecta mudança e atualiza `prompt_voz` automaticamente
4. ✅ Tudo funciona sem timeout e sem atualizações manuais
