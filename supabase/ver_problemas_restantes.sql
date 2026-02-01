-- ============================================================================
-- VER PROBLEMAS RESTANTES: SQL simples para identificar o que falta
-- Execute este SQL e me envie o resultado COMPLETO
-- ============================================================================

-- 1. BLOCOS COM IDs DE TESTE
SELECT 
  '⚠️ BLOCOS COM IDs DE TESTE' as tipo,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%';

-- 2. ROTAS COM IDs DE TESTE
SELECT 
  '⚠️ ROTAS COM IDs DE TESTE' as tipo,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%';

-- 3. BLOCOS SEM assistente_id (mas flow tem)
SELECT 
  '⚠️ BLOCOS SEM assistente_id (flow tem)' as tipo,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id IS NULL OR fb.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';

-- 4. ROTAS SEM assistente_id (mas flow tem)
SELECT 
  '⚠️ ROTAS SEM assistente_id (flow tem)' as tipo,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';

-- 5. BLOCOS QUE NÃO BATEM COM FLOW
SELECT 
  '❌ BLOCOS QUE NÃO BATEM COM FLOW' as tipo,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id IS NOT NULL
  AND fb.assistente_id != ''
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND fb.assistente_id != f.assistente_id;

-- 6. ROTAS QUE NÃO BATEM COM FLOW
SELECT 
  '❌ ROTAS QUE NÃO BATEM COM FLOW' as tipo,
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

-- 7. DETALHES DOS BLOCOS COM PROBLEMAS
SELECT 
  '📋 DETALHES - BLOCOS COM PROBLEMAS' as tipo,
  fb.block_key,
  fb.block_type,
  COALESCE(fb.assistente_id, 'NULL') as assistente_id_bloco,
  COALESCE(f.assistente_id, 'NULL') as assistente_id_flow,
  f.name as flow_name
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (
  fb.assistente_id LIKE 'assistente-teste-%'
  OR fb.tenant_id LIKE 'tenant-teste-%'
  OR (fb.assistente_id IS NULL AND f.assistente_id IS NOT NULL AND f.assistente_id != '')
  OR (fb.assistente_id IS NOT NULL AND fb.assistente_id != '' AND f.assistente_id IS NOT NULL AND f.assistente_id != '' AND fb.assistente_id != f.assistente_id)
)
ORDER BY fb.created_at DESC
LIMIT 20;

-- 8. DETALHES DAS ROTAS COM PROBLEMAS
SELECT 
  '📋 DETALHES - ROTAS COM PROBLEMAS' as tipo,
  fr.route_key,
  COALESCE(fr.assistente_id, 'NULL') as assistente_id_rota,
  COALESCE(f.assistente_id, 'NULL') as assistente_id_flow,
  f.name as flow_name
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (
  fr.assistente_id LIKE 'assistente-teste-%'
  OR fr.tenant_id LIKE 'tenant-teste-%'
  OR (fr.assistente_id IS NULL AND f.assistente_id IS NOT NULL AND f.assistente_id != '')
  OR (fr.assistente_id IS NOT NULL AND fr.assistente_id != '' AND f.assistente_id IS NOT NULL AND f.assistente_id != '' AND fr.assistente_id != f.assistente_id)
)
ORDER BY fr.created_at DESC
LIMIT 20;
