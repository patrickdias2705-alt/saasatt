-- ============================================================================
-- CORREÇÃO ESPECÍFICA: Corrigir apenas blocos e rotas com IDs de teste
-- Baseado no diagnóstico: 32 blocos e 11 rotas com IDs de teste
-- ============================================================================

-- 1. CORRIGIR BLOCOS COM IDs DE TESTE
-- Atualizar blocos que têm assistente_id ou tenant_id de teste para usar os valores REAIS do flow
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
    fb.assistente_id LIKE 'assistente-teste-%'  -- Bloco tem ID de teste
    OR fb.tenant_id LIKE 'tenant-teste-%'  -- Bloco tem tenant de teste
  );

-- 2. CORRIGIR ROTAS COM IDs DE TESTE
-- Atualizar rotas que têm assistente_id ou tenant_id de teste para usar os valores REAIS do flow
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
    fr.assistente_id LIKE 'assistente-teste-%'  -- Rota tem ID de teste
    OR fr.tenant_id LIKE 'tenant-teste-%'  -- Rota tem tenant de teste
  );

-- 3. VERIFICAÇÃO: Ver quantos foram corrigidos
SELECT 
  '✅ Blocos corrigidos (agora com IDs reais)' as status,
  COUNT(*) as total
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id = f.assistente_id
  AND fb.tenant_id = f.tenant_id
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''

UNION ALL

SELECT 
  '⚠️ Blocos ainda com IDs de teste' as status,
  COUNT(*) as total
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'

UNION ALL

SELECT 
  '✅ Rotas corrigidas (agora com IDs reais)' as status,
  COUNT(*) as total
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id = f.assistente_id
  AND fr.tenant_id = f.tenant_id
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''

UNION ALL

SELECT 
  '⚠️ Rotas ainda com IDs de teste' as status,
  COUNT(*) as total
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%';

-- 4. VER DETALHES: Quais blocos/rotas foram corrigidos
SELECT 
  '📋 Blocos que foram corrigidos' as tipo,
  fb.block_key,
  fb.block_type,
  'ANTES: ' || COALESCE(fb_old.assistente_id, 'NULL') || ' → DEPOIS: ' || fb.assistente_id as correcao,
  f.name as flow_name
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
LEFT JOIN (
  SELECT id, assistente_id 
  FROM flow_blocks 
  WHERE assistente_id LIKE 'assistente-teste-%'
) fb_old ON fb_old.id = fb.id
WHERE fb.assistente_id NOT LIKE 'assistente-teste-%'
  AND fb.assistente_id IS NOT NULL
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
LIMIT 10;
