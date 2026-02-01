# ✅ Solução Final: Remover Sincronização com prompt_voz

## 🔍 Problema Identificado

O timeout ao salvar blocos é causado por **triggers SQL** que tentam sincronizar automaticamente o campo `prompt_voz` na tabela `assistentes` toda vez que um bloco é atualizado em `flow_blocks`. Esses triggers executam funções pesadas que causam timeout.

## ✅ Solução Implementada

### 1. Script SQL Criado
**Arquivo:** `supabase/REMOVER_SINCRONIZACAO_PROMPT_VOZ_DEFINITIVO.sql`

Este script:
- ✅ Remove **TODOS** os triggers relacionados a `prompt_voz`
- ✅ Remove **TODAS** as funções de sincronização
- ✅ Recria a função `update_flow_block_simple` de forma simples e rápida
- ✅ Inclui `assistente_id` e `tenant_id` automaticamente (busca do `flows`)

### 2. Função RPC Otimizada

A função `update_flow_block_simple` agora:
- ✅ Busca `assistente_id` e `tenant_id` do `flows` automaticamente
- ✅ Faz UPDATE/INSERT direto sem triggers pesados
- ✅ Não sincroniza mais com `prompt_voz`
- ✅ É rápida e não causa timeout

## 📋 O Que Você Precisa Fazer

### Passo 1: Executar o Script SQL no Supabase

1. Abra o **Supabase SQL Editor**
2. Execute o arquivo: `saas_server/supabase/REMOVER_SINCRONIZACAO_PROMPT_VOZ_DEFINITIVO.sql`
3. Verifique que o resultado mostra:
   - ✅ Triggers removidos
   - ✅ Função `update_flow_block_simple` criada

### Passo 2: Testar no Flow Editor

1. Abra o Flow Editor para um assistente
2. Edite um bloco (ex: PM001)
3. Clique em "Salvar"
4. **Deve funcionar sem timeout!**

## 🔍 Verificação

Execute este SQL para verificar que não há mais triggers pesados:

```sql
SELECT 
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
    WHEN tgenabled = 'O' THEN '❌ ATIVO'
    ELSE 'Status: ' || tgenabled
  END as status
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass
  AND (tgname LIKE '%prompt_voz%' OR tgname LIKE '%sync%');
```

**Resultado esperado:** Nenhuma linha (todos os triggers foram removidos)

## ⚠️ Importante

- **Não há mais sincronização automática** entre `flow_blocks` e `prompt_voz`
- As mudanças em blocos **só afetam** a tabela `flow_blocks`
- O `prompt_voz` na tabela `assistentes` **não será mais atualizado automaticamente**

## 🚀 Servidor

O servidor foi reiniciado na porta **8081** e está pronto para uso.

---

**Execute o script SQL e teste!** 🎯
