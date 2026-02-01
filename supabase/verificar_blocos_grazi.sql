-- ============================================================================
-- VERIFICAR SE HÁ BLOCOS COM CONTEÚDO DA GRAZI NO BANCO
-- Execute este SQL para ver se os blocos estão salvos no banco com esse conteúdo
-- ============================================================================

-- 1. BUSCAR BLOCOS COM CONTEÚDO DA GRAZI
SELECT 
  '🔍 BLOCOS COM CONTEÚDO DA GRAZI' as tipo,
  fb.id::text as block_id,
  fb.block_key,
  fb.block_type,
  fb.content,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.content ILIKE '%Grazi%'
   OR fb.content ILIKE '%assistente virtual da Salesdever%'
   OR fb.content ILIKE '%Vi sua aplicação%'
   OR fb.content ILIKE '%adoraria conhecer melhor seu cenário%'
ORDER BY fb.created_at DESC
LIMIT 20;

-- 2. CONTAR QUANTOS BLOCOS TÊM ESSE CONTEÚDO
SELECT 
  '📊 CONTAGEM' as tipo,
  'Blocos com conteúdo da Grazi' as item,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE content ILIKE '%Grazi%'
   OR content ILIKE '%assistente virtual da Salesdever%'
   OR content ILIKE '%Vi sua aplicação%'
   OR content ILIKE '%adoraria conhecer melhor seu cenário%';

-- 3. VER TODOS OS CONTEÚDOS DE PRIMEIRA_MENSAGEM
SELECT 
  '🔍 CONTEÚDOS DE PRIMEIRA_MENSAGEM' as tipo,
  fb.block_key,
  LEFT(fb.content, 100) as content_preview,
  f.name as flow_name,
  f.assistente_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.block_type = 'primeira_mensagem'
ORDER BY fb.created_at DESC
LIMIT 20;
