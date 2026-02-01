-- ============================================================================
-- DELETAR APENAS FLOWS DE TESTE (SEGURO)
-- Este script deleta APENAS flows/blocos/rotas com assistente-teste-XXX ou tenant-teste-XXX
-- NÃO mexe em dados reais! Apenas padrões exatos: assistente-teste-001, tenant-teste-001, etc.
-- ============================================================================

-- 1. VER O QUE SERÁ DELETADO (ANTES DE DELETAR!)
SELECT 
  '⚠️ FLOWS QUE SERÃO DELETADOS' as tipo,
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

-- 2. VER QUANTOS BLOCOS/ROTAS SERÃO DELETADOS
SELECT 
  '📊 RESUMO DO QUE SERÁ DELETADO' as tipo,
  'Flows' as item,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flows
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
UNION ALL
SELECT 
  '📊 RESUMO DO QUE SERÁ DELETADO' as tipo,
  'Blocos' as item,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE flow_id IN (
  SELECT id FROM flows 
  WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
     OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
)
UNION ALL
SELECT 
  '📊 RESUMO DO QUE SERÁ DELETADO' as tipo,
  'Rotas' as item,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE flow_id IN (
  SELECT id FROM flows 
  WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
     OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
);

-- 3. DELETAR ROTAS DE FLOWS DE TESTE (apenas assistente-teste-XXX e tenant-teste-XXX)
DELETE FROM flow_routes 
WHERE flow_id IN (
  SELECT id FROM flows 
  WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
     OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
);

-- 4. DELETAR BLOCOS DE FLOWS DE TESTE (apenas assistente-teste-XXX e tenant-teste-XXX)
DELETE FROM flow_blocks 
WHERE flow_id IN (
  SELECT id FROM flows 
  WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
     OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
);

-- 5. DELETAR FLOWS DE TESTE (apenas assistente-teste-XXX e tenant-teste-XXX)
DELETE FROM flows 
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$');

-- 6. VERIFICAÇÃO FINAL: Deve mostrar 0 para tudo
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Flows com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flows
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Blocos com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_blocks
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$')
UNION ALL
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  'Rotas com IDs de teste' as problema,
  COUNT(*)::text as total,
  '' as valor2,
  '' as valor3
FROM flow_routes
WHERE (assistente_id LIKE 'assistente-teste-%' AND assistente_id ~ '^assistente-teste-[0-9]+$')
   OR (tenant_id LIKE 'tenant-teste-%' AND tenant_id ~ '^tenant-teste-[0-9]+$');
