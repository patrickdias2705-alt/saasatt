# Corrigir Rotas com NULL - Flow de Teste

## Problema Identificado

Há **11 rotas** com `assistente_id = NULL` que pertencem ao flow de teste:
- **Flow:** "Flow Universal de Teste - Voz"
- **assistente_id do flow:** `assistente-teste-001`

Essas rotas ficaram com NULL porque o script anterior deixou NULL quando o flow também tinha ID de teste.

## Solução

Execute este script:

```sql
saas_server/supabase/corrigir_rotas_null_flow_teste.sql
```

Este script:
1. ✅ Corrige rotas com NULL que pertencem a flows de teste
2. ✅ Corrige blocos com NULL que pertencem a flows de teste
3. ✅ Usa o `assistente_id` e `tenant_id` do flow
4. ✅ Mostra verificação final

## Opção: Deletar Flow de Teste

Se o flow "Flow Universal de Teste - Voz" não for necessário em produção, você pode deletá-lo completamente. Descomente as linhas no final do script:

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

## Após Executar

O script mostra:
- ✅ Quantas rotas foram corrigidas
- ✅ Quantas rotas ainda têm NULL (deve ser 0)
- ✅ Verificação final

## Resultado Esperado

Após executar:
- ✅ **0 rotas com NULL** (que pertencem a flows com assistente_id)
- ✅ Todas as rotas têm `assistente_id` preenchido

Execute o script e me diga o resultado!
