-- ============================================================================
-- CORREÇÃO FORÇADA: Corrigir TODOS os blocos/rotas com IDs de teste
-- Este script FORÇA a correção mesmo se o flow também tiver ID de teste
-- ============================================================================

-- 1. VER QUAIS FLOWS TÊM IDs DE TESTE (para entender o problema)
SELECT 
  '🔍 FLOWS COM IDs DE TESTE' as tipo,
  id::text as flow_id,
  name as flow_name,
  assistente_id,
  tenant_id
FROM flows
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
ORDER BY created_at DESC;

-- 2. CORRIGIR BLOCOS: Se o flow tem assistente_id real, usar ele
--    Se o flow também tem ID de teste, deixar NULL (será corrigido depois)
UPDATE flow_blocks fb
SET 
  assistente_id = CASE 
    WHEN f.assistente_id IS NOT NULL 
      AND f.assistente_id != '' 
      AND f.assistente_id NOT LIKE 'assistente-teste-%' 
    THEN f.assistente_id
    ELSE NULL  -- Se flow também tem ID de teste, deixar NULL
  END,
  tenant_id = CASE 
    WHEN f.tenant_id IS NOT NULL 
      AND f.tenant_id != '' 
      AND f.tenant_id NOT LIKE 'tenant-teste-%' 
    THEN f.tenant_id
    ELSE NULL  -- Se flow também tem ID de teste, deixar NULL
  END
FROM flows f
WHERE fb.flow_id = f.id
  AND (
    fb.assistente_id LIKE 'assistente-teste-%'
    OR fb.tenant_id LIKE 'tenant-teste-%'
  );

-- 3. CORRIGIR ROTAS: Se o flow tem assistente_id real, usar ele
--    Se o flow também tem ID de teste, deixar NULL (será corrigido depois)
UPDATE flow_routes fr
SET 
  assistente_id = CASE 
    WHEN f.assistente_id IS NOT NULL 
      AND f.assistente_id != '' 
      AND f.assistente_id NOT LIKE 'assistente-teste-%' 
    THEN f.assistente_id
    ELSE NULL  -- Se flow também tem ID de teste, deixar NULL
  END,
  tenant_id = CASE 
    WHEN f.tenant_id IS NOT NULL 
      AND f.tenant_id != '' 
      AND f.tenant_id NOT LIKE 'tenant-teste-%' 
    THEN f.tenant_id
    ELSE NULL  -- Se flow também tem ID de teste, deixar NULL
  END
FROM flows f
WHERE fr.flow_id = f.id
  AND (
    fr.assistente_id LIKE 'assistente-teste-%'
    OR fr.tenant_id LIKE 'tenant-teste-%'
  );

-- 4. SE HOUVER FLOWS COM IDs DE TESTE, DELETAR SEUS BLOCOS/ROTAS
--    (esses são flows de teste que não devem existir em produção)
--    ATENÇÃO: Descomente apenas se quiser deletar flows de teste!

-- DELETE FROM flow_routes 
-- WHERE flow_id IN (
--   SELECT id FROM flows 
--   WHERE assistente_id LIKE 'assistente-teste-%'
--      OR tenant_id LIKE 'tenant-teste-%'
-- );

-- DELETE FROM flow_blocks 
-- WHERE flow_id IN (
--   SELECT id FROM flows 
--   WHERE assistente_id LIKE 'assistente-teste-%'
--      OR tenant_id LIKE 'tenant-teste-%'
-- );

-- DELETE FROM flows 
-- WHERE assistente_id LIKE 'assistente-teste-%'
--    OR tenant_id LIKE 'tenant-teste-%';

-- 5. VERIFICAÇÃO FINAL
SELECT 
  '✅ RESULTADO' as tipo,
  'Blocos ainda com IDs de teste' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  '✅ RESULTADO' as tipo,
  'Rotas ainda com IDs de teste' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE assistente_id LIKE 'assistente-teste-%'
   OR tenant_id LIKE 'tenant-teste-%'
UNION ALL
SELECT 
  '✅ RESULTADO' as tipo,
  'Blocos corrigidos (com IDs reais)' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id = f.assistente_id
  AND fb.assistente_id NOT LIKE 'assistente-teste-%'
  AND fb.assistente_id IS NOT NULL
UNION ALL
SELECT 
  '✅ RESULTADO' as tipo,
  'Rotas corrigidas (com IDs reais)' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id = f.assistente_id
  AND fr.assistente_id NOT LIKE 'assistente-teste-%'
  AND fr.assistente_id IS NOT NULL;

-- 6. VER DETALHES DOS BLOCOS/ROTAS QUE AINDA TÊM IDs DE TESTE
SELECT 
  '⚠️ BLOCOS QUE AINDA TÊM IDs DE TESTE' as tipo,
  fb.block_key,
  fb.block_type,
  fb.assistente_id as assistente_id_bloco,
  f.assistente_id as assistente_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id LIKE 'assistente-teste-%'
   OR fb.tenant_id LIKE 'tenant-teste-%'
ORDER BY fb.created_at DESC
LIMIT 20;

SELECT 
  '⚠️ ROTAS QUE AINDA TÊM IDs DE TESTE' as tipo,
  fr.route_key,
  fr.assistente_id as assistente_id_rota,
  f.assistente_id as assistente_id_flow,
  f.name as flow_name,
  f.id::text as flow_id
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id LIKE 'assistente-teste-%'
   OR fr.tenant_id LIKE 'tenant-teste-%'
ORDER BY fr.created_at DESC
LIMIT 20;
