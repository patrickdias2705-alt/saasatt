-- ============================================================================
-- VERIFICAÇÃO FINAL: Confirmar que não há mais IDs de teste
-- Execute este SQL para verificar se tudo está correto
-- ============================================================================

-- 1. RESUMO FINAL
SELECT 
  '📊 RESUMO FINAL' as tipo,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Total de blocos' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks
UNION ALL
SELECT 
  'Total de rotas' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes;

-- 2. VERIFICAR SE AINDA HÁ IDs DE TESTE
SELECT 
  '⚠️ PROBLEMAS ENCONTRADOS' as tipo,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Blocos com assistente_id de teste' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
UNION ALL
SELECT 
  'Blocos com tenant_id de teste' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  'Rotas com assistente_id de teste' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
UNION ALL
SELECT 
  'Rotas com tenant_id de teste' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE tenant_id LIKE 'tenant-teste-%';

-- 3. VERIFICAR SE HÁ BLOCOS/ROTAS SEM assistente_id
SELECT 
  '⚠️ BLOCOS/ROTAS SEM assistente_id' as tipo,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Blocos sem assistente_id' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id IS NULL OR assistente_id = ''
UNION ALL
SELECT 
  'Rotas sem assistente_id' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id IS NULL OR assistente_id = '';

-- 4. VERIFICAR SE BLOCOS/ROTAS BATEM COM O FLOW
SELECT 
  '❌ BLOCOS/ROTAS QUE NÃO BATEM COM FLOW' as tipo,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Blocos com assistente_id diferente do flow' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id IS NULL OR fb.assistente_id != f.assistente_id)
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
UNION ALL
SELECT 
  'Rotas com assistente_id diferente do flow' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id != f.assistente_id)
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';

-- 5. VER TODOS OS assistente_id ÚNICOS (para confirmar que são reais)
SELECT 
  '🔍 assistente_id ÚNICOS NOS BLOCOS' as tipo,
  assistente_id as item,
  tenant_id as valor1,
  COUNT(*)::text as valor2,
  string_agg(DISTINCT block_type, ', ') as valor3
FROM flow_blocks
WHERE assistente_id IS NOT NULL 
  AND assistente_id != ''
  AND assistente_id NOT LIKE 'assistente-teste-%'
GROUP BY assistente_id, tenant_id
ORDER BY COUNT(*) DESC;

-- 6. VER TODOS OS assistente_id ÚNICOS NAS ROTAS
SELECT 
  '🔍 assistente_id ÚNICOS NAS ROTAS' as tipo,
  assistente_id as item,
  tenant_id as valor1,
  COUNT(*)::text as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id IS NOT NULL 
  AND assistente_id != ''
  AND assistente_id NOT LIKE 'assistente-teste-%'
GROUP BY assistente_id, tenant_id
ORDER BY COUNT(*) DESC;

-- 7. VERIFICAR SE TUDO ESTÁ OK (deve retornar 0 para tudo)
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  CASE 
    WHEN (
      (SELECT COUNT(*) FROM flow_blocks WHERE assistente_id LIKE 'assistente-teste-%' OR tenant_id LIKE 'tenant-teste-%') = 0
      AND (SELECT COUNT(*) FROM flow_routes WHERE assistente_id LIKE 'assistente-teste-%' OR tenant_id LIKE 'tenant-teste-%') = 0
      AND (SELECT COUNT(*) FROM flow_blocks WHERE assistente_id IS NULL OR assistente_id = '') = 0
      AND (SELECT COUNT(*) FROM flow_routes WHERE assistente_id IS NULL OR assistente_id = '') = 0
    ) THEN '✅ TUDO CORRETO!'
    ELSE '⚠️ AINDA HÁ PROBLEMAS'
  END as item,
  '' as valor1,
  '' as valor2,
  '' as valor3;
