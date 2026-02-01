-- ============================================================================
-- REMOVER BLOCOS CRIADOS NO LOVABLE PARA UM ASSISTENTE ESPECÍFICO
-- Execute este SQL substituindo 'SEU_ASSISTENTE_ID' pelo ID real do assistente
-- ============================================================================

-- ⚠️ SUBSTITUA 'SEU_ASSISTENTE_ID' PELO ID DO ASSISTENTE "Copy - assistente de indicação - clinica"
-- Exemplo: 'copy-assistente-indicacao-clinica' ou o ID real

-- 1. VER QUAIS BLOCOS EXISTEM PARA ESTE ASSISTENTE (ANTES DE DELETAR)
SELECT 
  '🔍 BLOCOS ANTES DE DELETAR' as tipo,
  fb.id::text as block_id,
  fb.block_key,
  fb.block_type,
  LEFT(fb.content, 100) as content_preview,
  f.assistente_id,
  f.name as flow_name
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY fb.order_index, fb.block_key;

-- 2. VER QUANTAS ROTAS EXISTEM
SELECT 
  '🛤️ ROTAS ANTES DE DELETAR' as tipo,
  COUNT(*)::text as total_rotas
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI

-- 3. DELETAR TODAS AS ROTAS DO FLOW DESTE ASSISTENTE
DELETE FROM flow_routes
WHERE flow_id IN (
  SELECT id FROM flows WHERE assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
);

-- 4. DELETAR TODOS OS BLOCOS DO FLOW DESTE ASSISTENTE
DELETE FROM flow_blocks
WHERE flow_id IN (
  SELECT id FROM flows WHERE assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
);

-- 5. VERIFICAR SE FOI DELETADO (DEVE RETORNAR VAZIO)
SELECT 
  '✅ VERIFICAÇÃO APÓS DELETAR' as tipo,
  COUNT(*)::text as blocos_restantes,
  'Deve ser 0' as esperado
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI

-- 6. VERIFICAR ROTAS RESTANTES (DEVE RETORNAR VAZIO)
SELECT 
  '✅ VERIFICAÇÃO ROTAS APÓS DELETAR' as tipo,
  COUNT(*)::text as rotas_restantes,
  'Deve ser 0' as esperado
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI

-- NOTA: O FLOW EM SI NÃO É DELETADO, APENAS OS BLOCOS E ROTAS
-- O prompt_base do flow permanece intacto
