-- ============================================================================
-- VERIFICAR ESTADO ATUAL DO FLOW EDITOR
-- ============================================================================
-- Execute este script para verificar o estado atual dos blocos e do trigger

-- 1. Verificar status do trigger
SELECT 
    '🔍 TRIGGER' as tipo,
    tgname as nome,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO (seguro)'
        WHEN tgenabled = 'O' THEN '⚠️ ATIVO (pode causar timeout!)'
        ELSE 'Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- 2. Listar flows recentes
SELECT 
    '📋 FLOWS' as tipo,
    id as flow_id,
    assistente_id,
    name,
    version,
    created_at
FROM flows
ORDER BY created_at DESC
LIMIT 5;

-- 3. Contar blocos por flow
SELECT 
    '📦 BLOCOS POR FLOW' as tipo,
    f.id as flow_id,
    f.name as flow_name,
    COUNT(fb.id) as total_blocos,
    STRING_AGG(fb.block_key, ', ' ORDER BY fb.order_index) as block_keys
FROM flows f
LEFT JOIN flow_blocks fb ON fb.flow_id = f.id
GROUP BY f.id, f.name
ORDER BY f.created_at DESC
LIMIT 5;

-- 4. Ver blocos de um flow específico (substitua o flow_id)
-- SELECT 
--     '📦 BLOCOS DETALHADOS' as tipo,
--     block_key,
--     block_type,
--     LEFT(content, 80) as content_preview,
--     next_block_key,
--     order_index
-- FROM flow_blocks
-- WHERE flow_id = 'SUBSTITUA_AQUI_O_FLOW_ID'
-- ORDER BY order_index;
