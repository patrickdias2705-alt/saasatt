-- ============================================================================
-- CORREÇÃO COMPLETA: Corrigir TODOS os problemas encontrados
-- Este script corrige: IDs de teste, NULLs, e valores que não batem
-- ============================================================================

-- 1. CORRIGIR BLOCOS: IDs de teste, NULLs, e valores que não batem
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
    -- Corrigir se for ID de teste
    fb.assistente_id LIKE 'assistente-teste-%'
    OR fb.tenant_id LIKE 'tenant-teste-%'
    -- Corrigir se for NULL mas flow tem
    OR (fb.assistente_id IS NULL AND f.assistente_id IS NOT NULL)
    OR (fb.tenant_id IS NULL AND f.tenant_id IS NOT NULL)
    -- Corrigir se não bater com flow
    OR (fb.assistente_id IS NOT NULL AND fb.assistente_id != f.assistente_id)
    OR (fb.tenant_id IS NOT NULL AND fb.tenant_id != f.tenant_id)
  );

-- 2. CORRIGIR ROTAS: IDs de teste, NULLs, e valores que não batem
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
    -- Corrigir se for ID de teste
    fr.assistente_id LIKE 'assistente-teste-%'
    OR fr.tenant_id LIKE 'tenant-teste-%'
    -- Corrigir se for NULL mas flow tem
    OR (fr.assistente_id IS NULL AND f.assistente_id IS NOT NULL)
    OR (fr.tenant_id IS NULL AND f.tenant_id IS NOT NULL)
    -- Corrigir se não bater com flow
    OR (fr.assistente_id IS NOT NULL AND fr.assistente_id != f.assistente_id)
    OR (fr.tenant_id IS NOT NULL AND fr.tenant_id != f.tenant_id)
  );

-- 3. VERIFICAÇÃO: Contar quantos foram corrigidos
SELECT 
  '✅ RESULTADO DA CORREÇÃO' as tipo,
  '' as item,
  '' as valor1,
  '' as valor2,
  '' as valor3
UNION ALL
SELECT 
  'Blocos corrigidos' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id = f.assistente_id
  AND fb.tenant_id = f.tenant_id
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
  AND f.assistente_id IS NOT NULL
UNION ALL
SELECT 
  'Rotas corrigidas' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id = f.assistente_id
  AND fr.tenant_id = f.tenant_id
  AND f.assistente_id NOT LIKE 'assistente-teste-%'
  AND f.assistente_id IS NOT NULL
UNION ALL
SELECT 
  'Blocos ainda com problemas' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE (
  fb.assistente_id LIKE 'assistente-teste-%'
  OR fb.tenant_id LIKE 'tenant-teste-%'
  OR (fb.assistente_id IS NULL AND f.assistente_id IS NOT NULL)
  OR (fb.assistente_id != f.assistente_id)
)
UNION ALL
SELECT 
  'Rotas ainda com problemas' as tipo,
  '' as item,
  COUNT(*)::text as valor1,
  '' as valor2,
  '' as valor3
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE (
  fr.assistente_id LIKE 'assistente-teste-%'
  OR fr.tenant_id LIKE 'tenant-teste-%'
  OR (fr.assistente_id IS NULL AND f.assistente_id IS NOT NULL)
  OR (fr.assistente_id != f.assistente_id)
);
