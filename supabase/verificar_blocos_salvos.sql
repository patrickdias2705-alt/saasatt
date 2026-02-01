-- ============================================================================
-- VERIFICAR COMO OS BLOCOS ESTÃO SALVOS NO BANCO
-- Mostra todos os blocos do flow com detalhes completos
-- ============================================================================

-- Substitua o flow_id ou assistente_id abaixo pelo seu
-- Flow ID: 39acbe34-4b1c-458a-b4ef-1580801ada3a
-- Assistente ID: e7dfde93-35d2-44ee-8c4b-589fd408d00b

-- 1. VER TODOS OS BLOCOS DO FLOW COM DETALHES
SELECT 
  '📦 BLOCOS DO FLOW' as tipo,
  fb.id::text as block_id,
  fb.block_key,
  fb.block_type,
  fb.content,
  fb.next_block_key,
  fb.variable_name,
  fb.analyze_variable,
  fb.order_index,
  fb.position_x,
  fb.position_y,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  fb.created_at
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA PELO SEU ASSISTENTE_ID
   OR f.id = '39acbe34-4b1c-458a-b4ef-1580801ada3a'  -- ⚠️ OU SUBSTITUA PELO SEU FLOW_ID
ORDER BY fb.order_index, fb.block_key;

-- 2. VER TODAS AS ROTAS DOS BLOCOS
SELECT 
  '🛤️ ROTAS DOS BLOCOS' as tipo,
  fr.id::text as route_id,
  fb.block_key,  -- block_key vem do flow_blocks, não do flow_routes
  fr.route_key,
  fr.label,
  fr.response,
  fr.keywords,
  fr.destination_type,
  fr.destination_block_key,
  fr.ordem,
  fr.cor,
  fr.is_fallback,
  fr.max_loop_attempts,
  fb.block_type,
  f.assistente_id
FROM flow_routes fr
JOIN flow_blocks fb ON fb.id = fr.block_id
JOIN flows f ON f.id = fr.flow_id
WHERE f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA PELO SEU ASSISTENTE_ID
   OR f.id = '39acbe34-4b1c-458a-b4ef-1580801ada3a'  -- ⚠️ OU SUBSTITUA PELO SEU FLOW_ID
ORDER BY fb.block_key, fr.ordem;

-- 3. RESUMO: CONTAR BLOCOS POR TIPO
SELECT 
  '📊 RESUMO POR TIPO' as tipo,
  fb.block_type,
  COUNT(*) as total,
  string_agg(fb.block_key, ', ' ORDER BY fb.order_index) as block_keys
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA PELO SEU ASSISTENTE_ID
   OR f.id = '39acbe34-4b1c-458a-b4ef-1580801ada3a'  -- ⚠️ OU SUBSTITUA PELO SEU FLOW_ID
GROUP BY fb.block_type
ORDER BY MIN(fb.order_index);

-- 4. VER CONTEÚDO COMPLETO DOS BLOCOS (para debug)
SELECT 
  '🔍 CONTEÚDO COMPLETO' as tipo,
  fb.block_key,
  fb.block_type,
  LEFT(fb.content, 200) as content_preview,
  LENGTH(fb.content) as content_length,
  fb.next_block_key,
  CASE 
    WHEN fb.content LIKE '%Falar%' AND fb.content LIKE '%=' THEN '⚠️ TEM TEXTO INTRODUTÓRIO'
    WHEN LENGTH(fb.content) < 10 THEN '⚠️ CONTEÚDO MUITO CURTO'
    ELSE '✅ OK'
  END as status_conteudo
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA PELO SEU ASSISTENTE_ID
   OR f.id = '39acbe34-4b1c-458a-b4ef-1580801ada3a'  -- ⚠️ OU SUBSTITUA PELO SEU FLOW_ID
ORDER BY fb.order_index;
