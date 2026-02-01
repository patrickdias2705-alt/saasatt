-- ============================================================================
-- VERIFICAÇÃO FINAL COMPLETA: Confirmar que TUDO está correto
-- Execute este SQL para confirmar que não há mais problemas
-- ============================================================================

-- 1. RESUMO GERAL
SELECT 
  '📊 RESUMO GERAL' as tipo,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Total de flows' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flows
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

-- 2. VERIFICAÇÃO FINAL DE PROBLEMAS (deve retornar 0 para tudo)
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Blocos com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Rotas com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Blocos sem assistente_id (flow tem)' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id IS NULL OR fb.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Rotas sem assistente_id (flow tem)' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Blocos que não batem com flow' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id IS NOT NULL
  AND fb.assistente_id != ''
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND fb.assistente_id != f.assistente_id
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Rotas que não batem com flow' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id IS NOT NULL
  AND fr.assistente_id != ''
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND fr.assistente_id != f.assistente_id;

-- 3. VER TODOS OS assistente_id ÚNICOS (para confirmar que são reais)
SELECT 
  '🔍 assistente_id ÚNICOS NOS BLOCOS' as tipo,
  assistente_id as item,
  tenant_id as valor1,
  COUNT(*)::text as total_blocos,
  string_agg(DISTINCT block_type, ', ') as tipos_blocos
FROM flow_blocks
WHERE assistente_id IS NOT NULL 
  AND assistente_id != ''
  AND assistente_id NOT LIKE 'assistente-teste-%'
GROUP BY assistente_id, tenant_id
ORDER BY COUNT(*) DESC;

-- 4. VER TODOS OS assistente_id ÚNICOS NAS ROTAS
SELECT 
  '🔍 assistente_id ÚNICOS NAS ROTAS' as tipo,
  assistente_id as item,
  tenant_id as valor1,
  COUNT(*)::text as total_rotas,
  '' as valor3
FROM flow_routes
WHERE assistente_id IS NOT NULL 
  AND assistente_id != ''
  AND assistente_id NOT LIKE 'assistente-teste-%'
GROUP BY assistente_id, tenant_id
ORDER BY COUNT(*) DESC;

-- 5. STATUS FINAL
SELECT 
  '🎉 STATUS FINAL' as tipo,
  CASE 
    WHEN (
      (SELECT COUNT(*) FROM flow_blocks WHERE assistente_id LIKE 'assistente-teste-%' OR tenant_id LIKE 'tenant-teste-%') = 0
      AND (SELECT COUNT(*) FROM flow_routes WHERE assistente_id LIKE 'assistente-teste-%' OR tenant_id LIKE 'tenant-teste-%') = 0
      AND (SELECT COUNT(*) FROM flow_blocks fb JOIN flows f ON f.id = fb.flow_id WHERE (fb.assistente_id IS NULL OR fb.assistente_id = '') AND f.assistente_id IS NOT NULL AND f.assistente_id != '') = 0
      AND (SELECT COUNT(*) FROM flow_routes fr JOIN flows f ON f.id = fr.flow_id WHERE (fr.assistente_id IS NULL OR fr.assistente_id = '') AND f.assistente_id IS NOT NULL AND f.assistente_id != '') = 0
      AND (SELECT COUNT(*) FROM flow_blocks fb JOIN flows f ON f.id = fb.flow_id WHERE fb.assistente_id IS NOT NULL AND fb.assistente_id != '' AND f.assistente_id IS NOT NULL AND f.assistente_id != '' AND fb.assistente_id != f.assistente_id) = 0
      AND (SELECT COUNT(*) FROM flow_routes fr JOIN flows f ON f.id = fr.flow_id WHERE fr.assistente_id IS NOT NULL AND fr.assistente_id != '' AND f.assistente_id IS NOT NULL AND f.assistente_id != '' AND fr.assistente_id != f.assistente_id) = 0
    ) THEN '✅ TUDO CORRETO! Todos os blocos e rotas têm IDs reais!'
    ELSE '⚠️ AINDA HÁ PROBLEMAS - Verifique acima'
  END as item,
  '' as valor1,
  '' as valor2,
  '' as valor3;
