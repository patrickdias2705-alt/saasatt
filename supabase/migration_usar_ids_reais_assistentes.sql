-- Migration para usar IDs REAIS dos assistentes (não dados de teste)
-- Este script identifica flows com assistente_id real e corrige os blocos/rotas

-- ============================================================================
-- 1. IDENTIFICAR FLOWS COM IDs REAIS (não de teste)
-- ============================================================================
-- Ver quais flows têm assistente_id real (não "assistente-teste-XXX")
SELECT 
  'Flows com assistente_id REAL' as tipo,
  id,
  name,
  assistente_id,
  tenant_id
FROM flows
WHERE assistente_id IS NOT NULL
  AND assistente_id != ''
  AND assistente_id NOT LIKE 'assistente-teste-%'
ORDER BY created_at DESC;

-- ============================================================================
-- 2. CORRIGIR BLOCOS: usar assistente_id e tenant_id REAIS do flow
-- ============================================================================
-- Atualizar blocos para usar os valores REAIS do flow (não de teste)
UPDATE flow_blocks fb
SET 
  assistente_id = f.assistente_id,
  tenant_id = f.tenant_id
FROM flows f
WHERE fb.flow_id = f.id
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND f.assistente_id NOT LIKE 'assistente-teste-%'  -- Só flows reais
  AND (
    fb.assistente_id IS NULL 
    OR fb.assistente_id = '' 
    OR fb.assistente_id LIKE 'assistente-teste-%'  -- Corrigir se for de teste
    OR fb.assistente_id != f.assistente_id  -- Ou se não bater com o flow
  );

-- ============================================================================
-- 3. CORRIGIR ROTAS: usar assistente_id e tenant_id REAIS do flow
-- ============================================================================
UPDATE flow_routes fr
SET 
  assistente_id = f.assistente_id,
  tenant_id = f.tenant_id
FROM flows f
WHERE fr.flow_id = f.id
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
  AND f.assistente_id NOT LIKE 'assistente-teste-%'  -- Só flows reais
  AND (
    fr.assistente_id IS NULL 
    OR fr.assistente_id = '' 
    OR fr.assistente_id LIKE 'assistente-teste-%'  -- Corrigir se for de teste
    OR fr.assistente_id != f.assistente_id  -- Ou se não bater com o flow
  );

-- ============================================================================
-- 4. LIMPAR BLOCOS/ROTAS DE TESTE (opcional - descomente se quiser deletar)
-- ============================================================================
-- ATENÇÃO: Isso vai deletar blocos/rotas de flows de teste!
-- Descomente apenas se quiser limpar dados de teste:

-- DELETE FROM flow_routes 
-- WHERE assistente_id LIKE 'assistente-teste-%' 
--    OR tenant_id LIKE 'tenant-teste-%';

-- DELETE FROM flow_blocks 
-- WHERE assistente_id LIKE 'assistente-teste-%' 
--    OR tenant_id LIKE 'tenant-teste-%';

-- ============================================================================
-- 5. VERIFICAÇÃO: Ver quantos foram corrigidos
-- ============================================================================
-- Blocos corrigidos (com IDs reais)
SELECT 
  '✅ Blocos com IDs REAIS' as status,
  COUNT(*) as total
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id = f.assistente_id
  AND fb.tenant_id = f.tenant_id
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''

UNION ALL

-- Blocos ainda com IDs de teste
SELECT 
  '⚠️ Blocos ainda com IDs de TESTE' as status,
  COUNT(*) as total
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'

UNION ALL

-- Rotas corrigidas (com IDs reais)
SELECT 
  '✅ Rotas com IDs REAIS' as status,
  COUNT(*) as total
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id = f.assistente_id
  AND fr.tenant_id = f.tenant_id
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''

UNION ALL

-- Rotas ainda com IDs de teste
SELECT 
  '⚠️ Rotas ainda com IDs de TESTE' as status,
  COUNT(*) as total
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%';

-- ============================================================================
-- 6. VERIFICAR SE HÁ BLOCOS/ROTAS QUE NÃO BATEM COM O FLOW
-- ============================================================================
-- Blocos que não batem
SELECT 
  '⚠️ Blocos com assistente_id diferente do flow' as problema,
  fb.id,
  fb.block_key,
  fb.assistente_id as block_assistente_id,
  f.assistente_id as flow_assistente_id,
  f.name as flow_name
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id != f.assistente_id OR fb.assistente_id IS NULL)
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
LIMIT 10;

-- Rotas que não batem
SELECT 
  '⚠️ Rotas com assistente_id diferente do flow' as problema,
  fr.id,
  fr.route_key,
  fr.assistente_id as route_assistente_id,
  f.assistente_id as flow_assistente_id,
  f.name as flow_name
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id != f.assistente_id OR fr.assistente_id IS NULL)
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
LIMIT 10;
