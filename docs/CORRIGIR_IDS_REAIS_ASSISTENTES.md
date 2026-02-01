# Corrigir IDs Reais dos Assistentes (não dados de teste)

## Problema

Os blocos e rotas estão com IDs de teste (`assistente-teste-001`, `tenant-teste-001`) ao invés dos IDs reais dos assistentes que você está editando.

## Solução

### Passo 1: Executar Migration de Correção

Execute no **SQL Editor do Supabase**:

```sql
saas_server/supabase/migration_usar_ids_reais_assistentes.sql
```

Este script:
1. ✅ Identifica flows com `assistente_id` REAL (não de teste)
2. ✅ Corrige todos os blocos/rotas para usar os IDs REAIS do flow
3. ✅ Ignora flows de teste (não mexe neles)
4. ✅ Mostra quantos foram corrigidos

### Passo 2: Verificar Resultados

O script mostra:
- ✅ Quantos blocos/rotas foram corrigidos (com IDs reais)
- ⚠️ Quantos ainda têm IDs de teste (se houver)
- ⚠️ Blocos/rotas que não batem com o flow (se houver)

### Passo 3: Limpar Dados de Teste (Opcional)

Se quiser deletar blocos/rotas de flows de teste, descomente as linhas no final do script:

```sql
DELETE FROM flow_routes 
WHERE assistente_id LIKE 'assistente-teste-%' 
   OR tenant_id LIKE 'tenant-teste-%';

DELETE FROM flow_blocks 
WHERE assistente_id LIKE 'assistente-teste-%' 
   OR tenant_id LIKE 'tenant-teste-%';
```

---

## Como Funciona Agora

### Quando você edita um assistente:

1. **Frontend** passa `assistente_id` e `tenant_id` reais na URL:
   ```
   /flow?assistente_id=2931b75b-76f3-476c-989d-12c45a9806d0&tenant_id=088a6cbd-4fc7-4010-8d96-8dbf2b9680bc
   ```

2. **API** busca ou cria flow com esses IDs:
   ```python
   flow = flow_service.get_flow_by_assistant(assistente_id)
   # ou cria novo com:
   create_flow(assistente_id=assistente_id, tenant_id=tenant_id)
   ```

3. **Ao salvar blocos/rotas**, o código Python usa os IDs do flow:
   ```python
   assistente_id = flow.get("assistente_id")  # ID REAL do assistente
   tenant_id = flow.get("tenant_id")  # ID REAL do tenant
   ```

### Garantias:

- ✅ Novos flows sempre usam IDs reais (vem da URL/API)
- ✅ Blocos/rotas salvos sempre usam IDs do flow (não hardcoded)
- ✅ Trigger automático mantém sincronizado

---

## Verificação Manual

Após executar a migration, verifique:

```sql
-- Ver blocos de um assistente específico
SELECT 
  fb.block_key,
  fb.block_type,
  fb.assistente_id,
  fb.tenant_id,
  f.name as flow_name
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU-ASSISTENTE-ID-AQUI'
ORDER BY fb.order_index;
```

Todos os blocos devem ter `assistente_id` igual ao `assistente_id` do flow.

---

## Se Ainda Houver Problemas

### Problema: Flow criado sem assistente_id

Se um flow foi criado sem `assistente_id`, você precisa atualizá-lo:

```sql
-- Atualizar flow específico
UPDATE flows 
SET assistente_id = 'assistente-id-real',
    tenant_id = 'tenant-id-real'
WHERE id = 'flow-id-aqui';

-- Depois executar a migration de correção novamente
```

### Problema: Blocos ainda com IDs de teste após migration

Execute a migration novamente - ela é idempotente (pode rodar várias vezes):

```sql
-- Rodar novamente a parte de correção
UPDATE flow_blocks fb
SET 
  assistente_id = f.assistente_id,
  tenant_id = f.tenant_id
FROM flows f
WHERE fb.flow_id = f.id
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
  AND (fb.assistente_id != f.assistente_id OR fb.assistente_id IS NULL);
```

---

## Prevenção

Para evitar que isso aconteça novamente:

1. ✅ **Sempre passe `assistente_id` e `tenant_id` na URL** quando abrir o Flow Editor
2. ✅ **O código Python valida** antes de salvar
3. ✅ **O trigger automático** mantém sincronizado

Se você criar um flow manualmente no banco, sempre inclua `assistente_id` e `tenant_id` válidos!
