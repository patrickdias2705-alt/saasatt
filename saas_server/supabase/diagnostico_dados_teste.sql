-- ============================================================================
-- DIAGNÓSTICO: Verificar dados de teste e problemas
-- Execute este SQL e me envie o resultado completo
-- ============================================================================

-- 1. RESUMO GERAL: Quantos flows/blocos/rotas existem
SELECT 
  '📊 RESUMO GERAL' as secao,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Total de flows' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flows
UNION ALL
SELECT 
  'Total de blocos' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks
UNION ALL
SELECT 
  'Total de rotas' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes;

-- 2. FLOWS: Ver todos os assistente_id e tenant_id únicos
SELECT 
  '🔍 FLOWS - assistente_id únicos' as secao,
  assistente_id as item,
  tenant_id as valor1,
  COUNT(*)::text as valor2,
  string_agg(name, ', ') as valor3
FROM flows
WHERE assistente_id IS NOT NULL AND assistente_id != ''
GROUP BY assistente_id, tenant_id
ORDER BY COUNT(*) DESC;

-- 3. FLOWS: Ver flows sem assistente_id
SELECT 
  '⚠️ FLOWS sem assistente_id' as secao,
  id::text as item,
  name as valor1,
  tenant_id as valor2,
  created_at::text as valor3
FROM flows
WHERE assistente_id IS NULL OR assistente_id = ''
ORDER BY created_at DESC
LIMIT 20;

-- 4. BLOCOS: Ver assistente_id únicos nos blocos
SELECT 
  '🔍 BLOCOS - assistente_id únicos' as secao,
  assistente_id as item,
  tenant_id as valor1,
  COUNT(*)::text as valor2,
  string_agg(DISTINCT block_type, ', ') as valor3
FROM flow_blocks
WHERE assistente_id IS NOT NULL AND assistente_id != ''
GROUP BY assistente_id, tenant_id
ORDER BY COUNT(*) DESC;

-- 5. BLOCOS: Ver blocos com IDs de teste
SELECT 
  '⚠️ BLOCOS com IDs de TESTE' as secao,
  block_key as item,
  block_type as valor1,
  assistente_id as valor2,
  tenant_id as valor3
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
ORDER BY created_at DESC
LIMIT 20;

-- 6. BLOCOS: Ver blocos sem assistente_id
SELECT 
  '⚠️ BLOCOS sem assistente_id' as secao,
  block_key as item,
  block_type as valor1,
  flow_id::text as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id IS NULL OR assistente_id = ''
ORDER BY created_at DESC
LIMIT 20;

-- 7. BLOCOS: Ver blocos que não batem com o flow
SELECT 
  '❌ BLOCOS com assistente_id diferente do flow' as secao,
  fb.block_key as item,
  fb.assistente_id as valor1,
  f.assistente_id as valor2,
  f.name as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id IS NULL OR fb.assistente_id != f.assistente_id)
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
LIMIT 20;

-- 8. ROTAS: Ver rotas com IDs de teste
SELECT 
  '⚠️ ROTAS com IDs de TESTE' as secao,
  route_key as item,
  assistente_id as valor1,
  tenant_id as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
ORDER BY created_at DESC
LIMIT 20;

-- 9. ROTAS: Ver rotas sem assistente_id
SELECT 
  '⚠️ ROTAS sem assistente_id' as secao,
  route_key as item,
  flow_id::text as valor1,
  block_id::text as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id IS NULL OR assistente_id = ''
ORDER BY created_at DESC
LIMIT 20;

-- 10. ROTAS: Ver rotas que não batem com o flow
SELECT 
  '❌ ROTAS com assistente_id diferente do flow' as secao,
  fr.route_key as item,
  fr.assistente_id as valor1,
  f.assistente_id as valor2,
  f.name as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id != f.assistente_id)
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
LIMIT 20;

-- 11. CONTAGEM FINAL: Resumo de problemas
SELECT 
  '📈 CONTAGEM DE PROBLEMAS' as secao,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Flows sem assistente_id' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flows
WHERE assistente_id IS NULL OR assistente_id = ''
UNION ALL
SELECT 
  'Blocos com IDs de teste' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  'Blocos sem assistente_id' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id IS NULL OR assistente_id = ''
UNION ALL
SELECT 
  'Blocos que não batem com flow' as secao,
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
  'Rotas com IDs de teste' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  'Rotas sem assistente_id' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id IS NULL OR assistente_id = ''
UNION ALL
SELECT 
  'Rotas que não batem com flow' as secao,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id != f.assistente_id)
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';
