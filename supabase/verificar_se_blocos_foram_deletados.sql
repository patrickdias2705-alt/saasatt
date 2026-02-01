-- ============================================================================
-- VERIFICAR SE OS BLOCOS FORAM DELETADOS DO BANCO
-- Execute este SQL substituindo 'SEU_ASSISTENTE_ID' pelo ID real do assistente
-- ============================================================================

-- ⚠️ SUBSTITUA 'SEU_ASSISTENTE_ID' PELO ID DO ASSISTENTE QUE VOCÊ ESTÁ EDITANDO

-- 1. VER O FLOW (DEVE EXISTIR)
SELECT 
  '✅ FLOW EXISTE' as status,
  f.id::text as flow_id,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  f.version,
  f.status,
  LEFT(f.prompt_base, 100) as prompt_preview
FROM flows f
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY f.created_at DESC
LIMIT 1;

-- 2. VERIFICAR SE HÁ BLOCOS (DEVE SER 0 SE FORAM DELETADOS)
SELECT 
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ NENHUM BLOCO NO BANCO (FORAM DELETADOS)'
    ELSE '✅ EXISTEM ' || COUNT(*)::text || ' BLOCOS NO BANCO'
  END as status,
  COUNT(*)::text as total_blocos
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI

-- 3. VERIFICAR SE HÁ ROTAS (DEVE SER 0 SE FORAM DELETADAS)
SELECT 
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ NENHUMA ROTA NO BANCO (FORAM DELETADAS)'
    ELSE '✅ EXISTEM ' || COUNT(*)::text || ' ROTAS NO BANCO'
  END as status,
  COUNT(*)::text as total_rotas
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID';  -- ⚠️ SUBSTITUA AQUI

-- 4. VER HISTÓRICO (ÚLTIMAS VERSÕES DO FLOW)
SELECT 
  '📜 HISTÓRICO DE VERSÕES' as tipo,
  f.version,
  f.updated_at,
  (SELECT COUNT(*) FROM flow_blocks WHERE flow_id = f.id) as blocos_nesta_versao,
  (SELECT COUNT(*) FROM flow_routes WHERE flow_id = f.id) as rotas_nesta_versao
FROM flows f
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY f.updated_at DESC;
