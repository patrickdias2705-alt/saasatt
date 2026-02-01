-- ============================================================================
-- CORREÇÃO IMEDIATA: Desabilitar Trigger e Verificar Status
-- ============================================================================
-- Execute este script NO SUPABASE SQL EDITOR antes de tentar salvar blocos

-- 1. DESABILITAR TRIGGER (OBRIGATÓRIO!)
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 2. Verificar se foi desabilitado
SELECT 
    '✅ Trigger Desabilitado' as status,
    tgname as nome,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
        WHEN tgenabled = 'O' THEN '❌ AINDA ATIVO!'
        ELSE 'Status desconhecido'
    END as status_trigger
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- 3. Verificar se há blocos duplicados (pode causar erro)
SELECT 
    '🔍 Verificando Duplicatas' as verificacao,
    flow_id,
    block_key,
    COUNT(*) as quantidade
FROM flow_blocks
GROUP BY flow_id, block_key
HAVING COUNT(*) > 1;

-- Se houver duplicatas acima, execute para limpar (substitua o flow_id):
-- DELETE FROM flow_blocks WHERE id IN (
--     SELECT id FROM (
--         SELECT id, ROW_NUMBER() OVER (PARTITION BY flow_id, block_key ORDER BY created_at DESC) as rn
--         FROM flow_blocks
--         WHERE flow_id = 'SUBSTITUA_PELO_FLOW_ID'
--     ) t WHERE rn > 1
-- );
