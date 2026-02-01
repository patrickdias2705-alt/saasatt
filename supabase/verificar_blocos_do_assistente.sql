-- ============================================================================
-- VERIFICAR SE HÁ BLOCOS NO BANCO PARA UM ASSISTENTE
-- Execute este SQL substituindo 'SEU_ASSISTENTE_ID' pelo ID real do assistente
-- ============================================================================

-- ⚠️ SUBSTITUA 'SEU_ASSISTENTE_ID' PELO ID DO ASSISTENTE QUE VOCÊ ESTÁ EDITANDO

-- 1. VER O FLOW DO ASSISTENTE
SELECT 
  '🔍 FLOW DO ASSISTENTE' as tipo,
  f.id::text as flow_id,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  f.version,
  f.status
FROM flows f
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY f.created_at DESC
LIMIT 1;

-- 2. VER QUANTOS BLOCOS EXISTEM PARA ESTE ASSISTENTE
SELECT 
  '📊 RESUMO DE BLOCOS' as tipo,
  COUNT(*)::text as total_blocos,
  COUNT(DISTINCT fb.block_type)::text as tipos_diferentes,
  STRING_AGG(DISTINCT fb.block_type, ', ') as tipos_encontrados
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI

-- 3. VER TODOS OS BLOCOS (DETALHADO)
SELECT 
  '📦 BLOCOS DETALHADOS' as tipo,
  fb.id::text as block_id,
  fb.block_key,
  fb.block_type,
  LEFT(fb.content, 100) as content_preview,
  fb.next_block_key,
  fb.order_index,
  fb.variable_name,
  f.assistente_id,
  f.tenant_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY fb.order_index, fb.block_key;

-- 4. VERIFICAR SE HÁ BLOCOS SEM block_key (PROBLEMA!)
SELECT 
  '⚠️ BLOCOS SEM block_key (PROBLEMA!)' as tipo,
  COUNT(*)::text as total_sem_key,
  STRING_AGG(fb.id::text, ', ') as ids_problematicos
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
  AND (fb.block_key IS NULL OR fb.block_key = '');

-- 5. VER ROTAS
SELECT 
  '🛤️ ROTAS' as tipo,
  COUNT(*)::text as total_rotas
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI
