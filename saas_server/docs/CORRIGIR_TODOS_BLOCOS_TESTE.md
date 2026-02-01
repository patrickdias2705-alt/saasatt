# Corrigir TODOS os Blocos com IDs de Teste

## Problema

Ainda há muitos blocos com `assistente_id` ou `tenant_id` de teste (`assistente-teste-XXX`, `tenant-teste-XXX`).

## Solução

Execute este script:

```sql
saas_server/supabase/corrigir_todos_blocos_ids_teste.sql
```

Este script:
1. ✅ Mostra quantos blocos têm IDs de teste
2. ✅ Mostra quais flows têm IDs de teste (e quantos blocos/rotas cada um tem)
3. ✅ **Corrige TODOS os blocos** que têm IDs de teste (usa o `assistente_id` do flow)
4. ✅ **Corrige TODAS as rotas** que têm IDs de teste ou NULL
5. ✅ Mostra verificação final

## Importante

O script corrige os blocos/rotas para usar o `assistente_id` do flow. Se o flow também tiver ID de teste, os blocos/rotas ficarão com o mesmo ID de teste (mas pelo menos ficam consistentes).

## Opção: Deletar Flows de Teste

Se você não precisa dos flows de teste em produção, pode deletá-los completamente. Descomente as linhas no final do script:

```sql
DELETE FROM flow_routes 
WHERE flow_id IN (
  SELECT id FROM flows 
  WHERE assistente_id LIKE 'assistente-teste-%'
     OR tenant_id LIKE 'tenant-teste-%'
);

DELETE FROM flow_blocks 
WHERE flow_id IN (
  SELECT id FROM flows 
  WHERE assistente_id LIKE 'assistente-teste-%'
     OR tenant_id LIKE 'tenant-teste-%'
);

DELETE FROM flows 
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%';
```

**⚠️ ATENÇÃO:** Isso vai deletar TODOS os flows que têm `assistente_id` ou `tenant_id` de teste, junto com todos os seus blocos e rotas!

## Após Executar

O script mostra:
- ✅ Quantos blocos/rotas foram corrigidos
- ✅ Quantos ainda têm IDs de teste (deve ser 0 se deletou os flows de teste)
- ✅ Quais flows têm IDs de teste (para você decidir se quer deletar)

## Resultado Esperado

Se você deletar os flows de teste:
- ✅ **0 blocos com IDs de teste**
- ✅ **0 rotas com IDs de teste**
- ✅ **0 flows com IDs de teste**

Se você não deletar os flows de teste:
- ✅ Blocos/rotas terão o mesmo `assistente_id` do flow (consistente)
- ⚠️ Mas ainda terão IDs de teste (porque o flow também tem)

Execute o script e me diga o resultado!
