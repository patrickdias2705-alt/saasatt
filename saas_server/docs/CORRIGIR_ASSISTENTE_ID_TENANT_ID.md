# Corrigir assistente_id e tenant_id em flow_blocks e flow_routes

## Problema

Se a migration anterior gerou valores falsos/incorretos de `assistente_id` e `tenant_id`, você precisa corrigir usando os valores **reais** do flow.

## Solução

### Passo 1: Executar Migration de Correção

Execute no **SQL Editor do Supabase**:

```sql
saas_server/supabase/migration_corrigir_assistente_id_tenant_id.sql
```

Este script:
1. ✅ **FORÇA** a atualização de `assistente_id` e `tenant_id` baseado nos valores REAIS do flow
2. ✅ Atualiza mesmo se já tiver valores (corrige valores incorretos)
3. ✅ Mostra quais flows/blocos/rotas têm problemas

### Passo 2: Verificar Resultados

O script mostra:
- ⚠️ Flows sem `assistente_id` ou `tenant_id`
- ⚠️ Blocos com `assistente_id` diferente do flow
- ⚠️ Rotas com `assistente_id` diferente do flow
- ✅ Resumo de quantos foram corrigidos

### Passo 3: Verificar Manualmente

Execute para verificar se está tudo correto:

```sql
-- Ver se há blocos com assistente_id diferente do flow
SELECT 
  fb.id,
  fb.block_key,
  fb.assistente_id as block_assistente_id,
  f.assistente_id as flow_assistente_id,
  f.name as flow_name
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id != f.assistente_id
   OR fb.tenant_id != f.tenant_id;
```

Se retornar 0 linhas, está tudo correto! ✅

---

## Código Python Atualizado

O código Python já foi atualizado para:
- ✅ Validar se `assistente_id` e `tenant_id` são válidos antes de salvar
- ✅ Só incluir nos blocos/rotas se os valores forem válidos (não NULL/vazios)
- ✅ Logar avisos se o flow não tiver valores válidos

---

## Prevenção Futura

Para evitar que isso aconteça novamente:

1. **Sempre crie flows com `assistente_id` e `tenant_id` válidos**
2. **O trigger automático** (criado na migration) mantém sincronizado quando o flow é atualizado
3. **O código Python** valida antes de salvar

---

## Se Ainda Houver Problemas

Se após executar a migration de correção ainda houver valores incorretos:

1. Verifique se os **flows** têm `assistente_id` e `tenant_id` corretos:
   ```sql
   SELECT id, name, assistente_id, tenant_id 
   FROM flows 
   WHERE assistente_id IS NULL OR tenant_id IS NULL;
   ```

2. Se os flows estiverem corretos mas os blocos/rotas não, execute a migration de correção novamente

3. Se os flows também estiverem incorretos, você precisa corrigir os flows primeiro:
   ```sql
   -- Exemplo: atualizar um flow específico
   UPDATE flows 
   SET assistente_id = 'assistente-correto-id',
       tenant_id = 'tenant-correto-id'
   WHERE id = 'flow-id-aqui';
   ```
