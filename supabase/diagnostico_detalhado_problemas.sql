-- ============================================================================
-- DIAGNÓSTICO DETALHADO: Identificar exatamente quais problemas restam
-- Execute este SQL e me envie o resultado completo
-- ============================================================================

-- 1. BLOCOS COM IDs DE TESTE (detalhado)
SELECT 
  '⚠️ BLOCOS COM IDs DE TESTE' as problema,
  fb.id::text as id_bloco,
  fb.block_key,
  fb.block_type,
  fb.assistente_id as assistente_id_bloco,
  fb.tenant_id as tenant_id_bloco,
  f.assistente_id as assistente_id_flow,
  f.tenant_id as tenant_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id LIKE 'assistente-teste-%'
   OR fb.tenant_id LIKE 'tenant-teste-%'
   OR (fb.assistente_id IS NULL AND f.assistente_id IS NOT NULL)
ORDER BY fb.created_at DESC;

-- 2. ROTAS COM IDs DE TESTE (detalhado)
SELECT 
  '⚠️ ROTAS COM IDs DE TESTE' as problema,
  fr.id::text as id_rota,
  fr.route_key,
  fr.assistente_id as assistente_id_rota,
  fr.tenant_id as tenant_id_rota,
  f.assistente_id as assistente_id_flow,
  f.tenant_id as tenant_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id LIKE 'assistente-teste-%'
   OR fr.tenant_id LIKE 'tenant-teste-%'
   OR (fr.assistente_id IS NULL AND f.assistente_id IS NOT NULL)
ORDER BY fr.created_at DESC;

-- 3. BLOCOS SEM assistente_id (mas flow tem)
SELECT 
  '⚠️ BLOCOS SEM assistente_id (flow tem)' as problema,
  fb.id::text as id_bloco,
  fb.block_key,
  fb.block_type,
  f.assistente_id as assistente_id_flow,
  f.tenant_id as tenant_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id IS NULL OR fb.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
ORDER BY fb.created_at DESC;

-- 4. ROTAS SEM assistente_id (mas flow tem)
SELECT 
  '⚠️ ROTAS SEM assistente_id (flow tem)' as problema,
  fr.id::text as id_rota,
  fr.route_key,
  f.assistente_id as assistente_id_flow,
  f.tenant_id as tenant_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
ORDER BY fr.created_at DESC;

-- 5. BLOCOS QUE NÃO BATEM COM FLOW
SELECT 
  '❌ BLOCOS QUE NÃO BATEM COM FLOW' as problema,
  fb.id::text as id_bloco,
  fb.block_key,
  fb.assistente_id as assistente_id_bloco,
  f.assistente_id as assistente_id_flow,
  fb.tenant_id as tenant_id_bloco,
  f.tenant_id as tenant_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id IS NOT NULL
  AND fb.assistente_id != ''
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND fb.assistente_id != f.assistente_id
ORDER BY fb.created_at DESC;

-- 6. ROTAS QUE NÃO BATEM COM FLOW
SELECT 
  '❌ ROTAS QUE NÃO BATEM COM FLOW' as problema,
  fr.id::text as id_rota,
  fr.route_key,
  fr.assistente_id as assistente_id_rota,
  f.assistente_id as assistente_id_flow,
  fr.tenant_id as tenant_id_rota,
  f.tenant_id as tenant_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id IS NOT NULL
  AND fr.assistente_id != ''
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND fr.assistente_id != f.assistente_id
ORDER BY fr.created_at DESC;

-- 7. CONTAGEM POR TIPO DE PROBLEMA
SELECT 
  '📊 CONTAGEM DE PROBLEMAS' as tipo,
  'Blocos com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  '📊 CONTAGEM DE PROBLEMAS' as tipo,
  'Rotas com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  '📊 CONTAGEM DE PROBLEMAS' as tipo,
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
  '📊 CONTAGEM DE PROBLEMAS' as tipo,
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
  '📊 CONTAGEM DE PROBLEMAS' as tipo,
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
  '📊 CONTAGEM DE PROBLEMAS' as tipo,
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
