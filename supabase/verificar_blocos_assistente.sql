-- ============================================================================
-- VERIFICAR BLOCOS DE UM ASSISTENTE ESPECÍFICO
-- Execute este SQL substituindo 'SEU_ASSISTENTE_ID' pelo ID real do assistente
-- ============================================================================

-- Substitua 'SEU_ASSISTENTE_ID' pelo ID do assistente que você está editando
-- Exemplo: 'assistente-teste-001' ou o ID real do seu assistente

-- 1. VER FLOW DO ASSISTENTE
SELECT 
  '🔍 FLOW DO ASSISTENTE' as tipo,
  f.id::text as flow_id,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  LEFT(f.prompt_base, 200) as prompt_base_preview,
  f.version,
  f.status
FROM flows f
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY f.created_at DESC
LIMIT 1;

-- 2. VER TODOS OS BLOCOS DO FLOW
SELECT 
  '📦 BLOCOS DO FLOW' as tipo,
  fb.id::text as block_id,
  fb.block_key,
  fb.block_type,
  LEFT(fb.content, 100) as content_preview,
  fb.next_block_key,
  fb.variable_name,
  fb.order_index,
  f.assistente_id,
  f.tenant_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY fb.order_index, fb.block_key;

-- 3. VER TODAS AS ROTAS DOS BLOCOS
SELECT 
  '🛤️ ROTAS DOS BLOCOS' as tipo,
  fr.id::text as route_id,
  fr.block_key,
  fr.route_key,
  fr.label,
  LEFT(fr.response, 80) as response_preview,
  fr.keywords,
  fr.destination_type,
  fr.destination_block_key,
  fr.ordem,
  fr.cor,
  fr.is_fallback,
  f.assistente_id
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY fr.block_key, fr.ordem;

-- 4. CONTAR BLOCOS E ROTAS
SELECT 
  '📊 RESUMO' as tipo,
  COUNT(DISTINCT fb.id)::text as total_blocos,
  COUNT(DISTINCT fr.id)::text as total_rotas,
  COUNT(DISTINCT CASE WHEN fb.block_type = 'primeira_mensagem' THEN fb.id END)::text as blocos_primeira_mensagem,
  COUNT(DISTINCT CASE WHEN fb.block_type = 'mensagem' THEN fb.id END)::text as blocos_mensagem,
  COUNT(DISTINCT CASE WHEN fb.block_type = 'aguardar' THEN fb.id END)::text as blocos_aguardar,
  COUNT(DISTINCT CASE WHEN fb.block_type = 'caminhos' THEN fb.id END)::text as blocos_caminhos,
  COUNT(DISTINCT CASE WHEN fb.block_type = 'encerrar' THEN fb.id END)::text as blocos_encerrar
FROM flows f
LEFT JOIN flow_blocks fb ON fb.flow_id = f.id
LEFT JOIN flow_routes fr ON fr.flow_id = f.id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI
