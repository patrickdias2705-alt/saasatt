-- Migration para CORRIGIR assistente_id e tenant_id em flow_blocks e flow_routes
-- Execute este script se os valores foram preenchidos incorretamente
-- Este script FORÇA a atualização baseado nos valores REAIS do flow

-- ============================================================================
-- 1. CORRIGIR assistente_id EM flow_blocks (FORÇAR atualização)
-- ============================================================================
UPDATE flow_blocks fb
SET assistente_id = f.assistente_id
FROM flows f
WHERE fb.flow_id = f.id
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND (fb.assistente_id IS NULL OR fb.assistente_id != f.assistente_id);

-- ============================================================================
-- 2. CORRIGIR tenant_id EM flow_blocks (FORÇAR atualização)
-- ============================================================================
UPDATE flow_blocks fb
SET tenant_id = f.tenant_id
FROM flows f
WHERE fb.flow_id = f.id
  AND f.tenant_id IS NOT NULL
  AND f.tenant_id != ''
  AND (fb.tenant_id IS NULL OR fb.tenant_id != f.tenant_id);

-- ============================================================================
-- 3. CORRIGIR assistente_id EM flow_routes (FORÇAR atualização)
-- ============================================================================
UPDATE flow_routes fr
SET assistente_id = f.assistente_id
FROM flows f
WHERE fr.flow_id = f.id
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND (fr.assistente_id IS NULL OR fr.assistente_id != f.assistente_id);

-- ============================================================================
-- 4. CORRIGIR tenant_id EM flow_routes (FORÇAR atualização)
-- ============================================================================
UPDATE flow_routes fr
SET tenant_id = f.tenant_id
FROM flows f
WHERE fr.flow_id = f.id
  AND f.tenant_id IS NOT NULL
  AND f.tenant_id != ''
  AND (fr.tenant_id IS NULL OR fr.tenant_id != f.tenant_id);

-- ============================================================================
-- 5. VERIFICAÇÃO: Ver se há problemas
-- ============================================================================
-- Ver flows sem assistente_id ou tenant_id
SELECT 
  '⚠️ FLOWS SEM assistente_id' as problema,
  id,
  name,
  assistente_id,
  tenant_id
FROM flows
WHERE assistente_id IS NULL OR assistente_id = ''
ORDER BY created_at DESC
LIMIT 10;

-- Ver blocos que não batem com o flow
SELECT 
  '⚠️ BLOCOS com assistente_id diferente do flow' as problema,
  fb.id as block_id,
  fb.block_key,
  fb.assistente_id as block_assistente_id,
  f.assistente_id as flow_assistente_id,
  f.name as flow_name
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id IS NOT NULL 
  AND f.assistente_id IS NOT NULL
  AND fb.assistente_id != f.assistente_id
LIMIT 10;

-- Ver rotas que não batem com o flow
SELECT 
  '⚠️ ROTAS com assistente_id diferente do flow' as problema,
  fr.id as route_id,
  fr.route_key,
  fr.assistente_id as route_assistente_id,
  f.assistente_id as flow_assistente_id,
  f.name as flow_name
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id IS NOT NULL 
  AND f.assistente_id IS NOT NULL
  AND fr.assistente_id != f.assistente_id
LIMIT 10;

-- Resumo final
SELECT 
  '✅ Blocos corrigidos' as status,
  COUNT(*) as total
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id = f.assistente_id
  AND fb.tenant_id = f.tenant_id
  AND f.assistente_id IS NOT NULL
  AND f.tenant_id IS NOT NULL;
