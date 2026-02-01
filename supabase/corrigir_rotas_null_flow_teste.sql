-- ============================================================================
-- CORRIGIR ROTAS COM NULL QUE PERTENCEM A FLOWS DE TESTE
-- Essas rotas têm assistente_id = NULL mas pertencem a flows com IDs de teste
-- ============================================================================

-- 1. VER QUANTAS ROTAS TÊM NULL MAS PERTENCEM A FLOWS DE TESTE
SELECT 
  '📊 ROTAS COM NULL (flow de teste)' as tipo,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id = '')
  AND (f.assistente_id LIKE 'assistente-teste-%' OR f.tenant_id LIKE 'tenant-teste-%');

-- 2. CORRIGIR ROTAS: Se o flow tem ID de teste, usar o ID do flow
UPDATE flow_routes fr
SET 
  assistente_id = f.assistente_id,
  tenant_id = f.tenant_id
FROM flows f
WHERE fr.flow_id = f.id
  AND (fr.assistente_id IS NULL OR fr.assistente_id = '')
  AND (f.assistente_id LIKE 'assistente-teste-%' OR f.tenant_id LIKE 'tenant-teste-%');

-- 3. CORRIGIR BLOCOS TAMBÉM (caso tenha algum NULL)
UPDATE flow_blocks fb
SET 
  assistente_id = f.assistente_id,
  tenant_id = f.tenant_id
FROM flows f
WHERE fb.flow_id = f.id
  AND (fb.assistente_id IS NULL OR fb.assistente_id = '')
  AND (f.assistente_id LIKE 'assistente-teste-%' OR f.tenant_id LIKE 'tenant-teste-%');

-- 4. VERIFICAÇÃO: Ver quantas rotas ainda têm NULL
SELECT 
  '✅ VERIFICAÇÃO' as tipo,
  'Rotas ainda com NULL (flow de teste)' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id = '')
  AND (f.assistente_id LIKE 'assistente-teste-%' OR f.tenant_id LIKE 'tenant-teste-%')
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO' as tipo,
  'Blocos ainda com NULL (flow de teste)' as status,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id IS NULL OR fb.assistente_id = '')
  AND (f.assistente_id LIKE 'assistente-teste-%' OR f.tenant_id LIKE 'tenant-teste-%');

-- 5. OPÇÃO: DELETAR FLOW DE TESTE COMPLETO (descomente se quiser)
-- ATENÇÃO: Isso vai deletar o flow "Flow Universal de Teste - Voz" e todos os seus blocos/rotas!
-- Só execute se esse flow não for necessário em produção

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

-- 6. VERIFICAÇÃO FINAL: Todos os problemas devem estar resolvidos
SELECT 
  '🎉 VERIFICAÇÃO FINAL' as tipo,
  'Rotas com NULL (flow de teste)' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (fr.assistente_id IS NULL OR fr.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != ''
UNION ALL
SELECT 
  '🎉 VERIFICAÇÃO FINAL' as tipo,
  'Blocos com NULL (flow tem)' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (fb.assistente_id IS NULL OR fb.assistente_id = '')
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';
