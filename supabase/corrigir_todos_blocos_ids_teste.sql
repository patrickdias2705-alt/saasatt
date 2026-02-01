-- ============================================================================
-- CORRIGIR TODOS OS BLOCOS COM IDs DE TESTE
-- Este script corrige TODOS os blocos que têm assistente_id ou tenant_id de teste
-- ============================================================================

-- 1. VER QUANTOS BLOCOS TÊM IDs DE TESTE (apenas assistente-teste-XXX e tenant-teste-XXX)
SELECT 
  '📊 BLOCOS COM IDs DE TESTE' as tipo,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$');

-- 2. VER QUAIS FLOWS TÊM IDs DE TESTE (apenas assistente-teste-XXX e tenant-teste-XXX)
SELECT 
  '🔍 FLOWS COM IDs DE TESTE' as tipo,
  id::text as flow_id,
  name as flow_name,
  assistente_id,
  tenant_id,
  (SELECT COUNT(*) FROM flow_blocks WHERE flow_id = flows.id)::text as total_blocos,
  (SELECT COUNT(*) FROM flow_routes WHERE flow_id = flows.id)::text as total_rotas
FROM flows
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
ORDER BY created_at DESC;

-- 3. CORRIGIR TODOS OS BLOCOS: Usar assistente_id e tenant_id do flow
--    Apenas blocos com assistente-teste-XXX ou tenant-teste-XXX
UPDATE flow_blocks fb
SET 
  assistente_id = f.assistente_id,
  tenant_id = f.tenant_id
FROM flows f
WHERE fb.flow_id = f.id
  AND (
    (fb.assistente_id LIKE 'assistente-teste-%' AND fb.assistente_id ~ '^assistente-teste-[0-9]+$')
    OR (fb.tenant_id LIKE 'tenant-teste-%' AND fb.tenant_id ~ '^tenant-teste-[0-9]+$')
  )
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';

-- 4. CORRIGIR TODAS AS ROTAS: Usar assistente_id e tenant_id do flow
--    Apenas rotas com assistente-teste-XXX ou tenant-teste-XXX (ou NULL)
UPDATE flow_routes fr
SET 
  assistente_id = f.assistente_id,
  tenant_id = f.tenant_id
FROM flows f
WHERE fr.flow_id = f.id
  AND (
    (fr.assistente_id LIKE 'assistente-teste-%' AND fr.assistente_id ~ '^assistente-teste-[0-9]+$')
    OR (fr.tenant_id LIKE 'tenant-teste-%' AND fr.tenant_id ~ '^tenant-teste-[0-9]+$')
    OR fr.assistente_id IS NULL
  )
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';

-- 5. VERIFICAÇÃO: Quantos blocos ainda têm IDs de teste (apenas assistente-teste-XXX e tenant-teste-XXX)
SELECT 
  '✅ VERIFICAÇÃO' as tipo,
  'Blocos ainda com IDs de teste' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO' as tipo,
  'Rotas ainda com IDs de teste' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$');

-- 6. VER DETALHES DOS BLOCOS QUE AINDA TÊM IDs DE TESTE (se houver)
--    Apenas assistente-teste-XXX e tenant-teste-XXX
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
WHERE (fb.assistente_id LIKE 'assistente-teste-%' AND fb.assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (fb.tenant_id LIKE 'tenant-teste-%' AND fb.tenant_id ~ '^tenant-teste-[0-9]+$')
ORDER BY fb.created_at DESC
LIMIT 20;

-- 7. OPÇÃO: DELETAR APENAS FLOWS DE TESTE (assistente-teste-XXX e tenant-teste-XXX)
--    ATENÇÃO: Isso vai deletar APENAS flows que têm assistente_id começando com "assistente-teste-"
--    OU tenant_id começando com "tenant-teste-". NÃO mexe em dados reais!
--    Descomente apenas se quiser limpar completamente os dados de teste

-- DELETE FROM flow_routes 
-- WHERE flow_id IN (
--   SELECT id FROM flows 
--   WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
--      OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
-- );

-- DELETE FROM flow_blocks 
-- WHERE flow_id IN (
--   SELECT id FROM flows 
--   WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
--      OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
-- );

-- DELETE FROM flows 
-- WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
--    OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$');

-- 8. VERIFICAÇÃO FINAL: Se deletou flows de teste, deve mostrar 0
--    Apenas assistente-teste-XXX e tenant-teste-XXX (não mexe em dados reais!)
SELECT 
  '🎉 VERIFICAÇÃO FINAL' as tipo,
  'Blocos com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
UNION ALL
SELECT 
  '🎉 VERIFICAÇÃO FINAL' as tipo,
  'Rotas com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
UNION ALL
SELECT 
  '🎉 VERIFICAÇÃO FINAL' as tipo,
  'Flows com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flows
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$');
