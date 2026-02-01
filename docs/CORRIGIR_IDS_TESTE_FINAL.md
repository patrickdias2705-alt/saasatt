# Correção Final - IDs de Teste

## Situação Atual

Ainda há:
- ⚠️ **32 blocos com IDs de teste**
- ⚠️ **11 rotas com IDs de teste**

## Possível Causa

Esses blocos/rotas podem estar vinculados a **flows que também têm IDs de teste**. Nesse caso, precisamos:

1. **Opção 1:** Corrigir os flows primeiro (se eles devem ter IDs reais)
2. **Opção 2:** Deletar flows de teste e seus blocos/rotas (se são apenas dados de teste)

## Solução

Execute este script:

```sql
saas_server/supabase/corrigir_forcar_ids_reais.sql
```

Este script:
1. ✅ Mostra quais flows têm IDs de teste
2. ✅ Corrige blocos/rotas se o flow tiver ID real
3. ✅ Se o flow também tiver ID de teste, deixa NULL (para você decidir depois)
4. ✅ Mostra detalhes dos blocos/rotas que ainda têm IDs de teste

## Se Ainda Houver Problemas

Se após executar ainda houver blocos/rotas com IDs de teste, provavelmente eles estão vinculados a **flows de teste**. Nesse caso:

### Opção A: Deletar Flows de Teste (Recomendado)

Se esses flows são apenas para teste e não devem existir em produção, descomente as linhas no final do script:

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

### Opção B: Corrigir Flows de Teste

Se esses flows devem existir mas com IDs reais, você precisa atualizar os flows primeiro:

```sql
-- Exemplo: atualizar um flow de teste para ter ID real
UPDATE flows 
SET assistente_id = 'id-real-do-assistente',
    tenant_id = 'id-real-do-tenant'
WHERE assistente_id LIKE 'assistente-teste-%';
```

Depois execute a correção novamente.

## Próximos Passos

1. Execute `corrigir_forcar_ids_reais.sql`
2. Veja quais flows têm IDs de teste (primeira query)
3. Decida: deletar flows de teste ou corrigi-los
4. Execute a ação escolhida
5. Execute a verificação final novamente

Me envie o resultado do script para eu ajudar a decidir a melhor ação!
