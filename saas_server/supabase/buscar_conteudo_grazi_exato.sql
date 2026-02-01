-- ============================================================================
-- BUSCAR CONTEÚDO EXATO DA GRAZI QUE O USUÁRIO MENCIONOU
-- Busca pelo texto exato: "Olá! Sou a Grazi, assistente virtual da Salesdever..."
-- ============================================================================

-- 1. BUSCAR BLOCOS COM O CONTEÚDO EXATO DA GRAZI
SELECT 
  '🔍 BLOCOS COM CONTEÚDO DA GRAZI' as tipo,
  fb.id::text as block_id,
  fb.block_key,
  fb.block_type,
  fb.content,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  f.id::text as flow_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.content LIKE '%Grazi%'
   OR fb.content LIKE '%assistente virtual da Salesdever%'
   OR fb.content LIKE '%Vi sua aplicação%'
   OR fb.content LIKE '%adoraria conhecer melhor seu cenário%'
   OR fb.content LIKE '%Tudo bem?%'
ORDER BY fb.created_at DESC;

-- 2. BUSCAR NO PROMPT_BASE TAMBÉM
SELECT 
  '🔍 PROMPT_BASE COM CONTEÚDO DA GRAZI' as tipo,
  id::text as flow_id,
  name as flow_name,
  assistente_id,
  LEFT(prompt_base, 200) as prompt_base_preview
FROM flows
WHERE prompt_base LIKE '%Grazi%'
   OR prompt_base LIKE '%assistente virtual da Salesdever%'
   OR prompt_base LIKE '%Vi sua aplicação%'
ORDER BY created_at DESC;

-- 3. VER TODOS OS BLOCOS DO FLOW ESPECÍFICO (se souber o assistente_id)
-- Substitua 'ASSISTENTE_ID_AQUI' pelo assistente_id que você está editando
SELECT 
  '🔍 TODOS OS BLOCOS DO FLOW' as tipo,
  fb.block_key,
  fb.block_type,
  fb.content,
  f.name as flow_name,
  f.assistente_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'ASSISTENTE_ID_AQUI'  -- SUBSTITUA PELO ID DO ASSISTENTE QUE VOCÊ ESTÁ EDITANDO
ORDER BY fb.order_index;

-- 4. VER TODOS OS BLOCOS (últimos 50)
SELECT 
  '🔍 ÚLTIMOS 50 BLOCOS CRIADOS' as tipo,
  fb.block_key,
  fb.block_type,
  LEFT(fb.content, 100) as content_preview,
  f.name as flow_name,
  f.assistente_id,
  fb.created_at
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
ORDER BY fb.created_at DESC
LIMIT 50;
