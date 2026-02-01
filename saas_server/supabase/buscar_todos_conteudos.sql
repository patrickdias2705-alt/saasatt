-- ============================================================================
-- BUSCAR TODOS OS CONTEÚDOS DE BLOCOS PARA IDENTIFICAR ONDE ESTÁ A GRAZI
-- Execute este SQL e me envie o resultado completo
-- ============================================================================

-- 1. TODOS OS BLOCOS COM SEUS CONTEÚDOS COMPLETOS
SELECT 
  '📋 TODOS OS BLOCOS' as tipo,
  fb.id::text as block_id,
  fb.block_key,
  fb.block_type,
  fb.content as content_completo,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  fb.created_at
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
ORDER BY fb.created_at DESC
LIMIT 100;

-- 2. BLOCOS COM CONTEÚDO QUE CONTÉM "Grazi" (case insensitive)
SELECT 
  '🔍 BLOCOS COM "Grazi"' as tipo,
  fb.block_key,
  fb.block_type,
  fb.content,
  f.name as flow_name,
  f.assistente_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE UPPER(fb.content) LIKE '%GRAZI%'
ORDER BY fb.created_at DESC;

-- 3. BLOCOS COM CONTEÚDO QUE CONTÉM "Salesdever"
SELECT 
  '🔍 BLOCOS COM "Salesdever"' as tipo,
  fb.block_key,
  fb.block_type,
  fb.content,
  f.name as flow_name,
  f.assistente_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE UPPER(fb.content) LIKE '%SALESDEVER%'
ORDER BY fb.created_at DESC;

-- 4. BLOCOS COM CONTEÚDO QUE CONTÉM "Vi sua aplicação"
SELECT 
  '🔍 BLOCOS COM "Vi sua aplicação"' as tipo,
  fb.block_key,
  fb.block_type,
  fb.content,
  f.name as flow_name,
  f.assistente_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.content LIKE '%Vi sua aplicação%'
ORDER BY fb.created_at DESC;

-- 5. PROMPT_BASE DE TODOS OS FLOWS (pode conter conteúdo da Grazi)
SELECT 
  '🔍 PROMPT_BASE DOS FLOWS' as tipo,
  id::text as flow_id,
  name as flow_name,
  assistente_id,
  LEFT(prompt_base, 500) as prompt_base_preview,
  LENGTH(prompt_base) as prompt_base_length
FROM flows
WHERE prompt_base IS NOT NULL
  AND prompt_base != ''
ORDER BY created_at DESC
LIMIT 20;
