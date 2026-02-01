-- ============================================================================
-- GARANTIR QUE O TRIGGER ESTÁ DESABILITADO
-- ============================================================================
-- Execute este script ANTES de salvar blocos no Flow Editor
-- O trigger causa timeout ao inserir blocos

-- 1. Desabilitar trigger
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 2. Verificar status
SELECT 
    '🔍 Status do Trigger' as verificacao,
    tgname as nome_trigger,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO (seguro para inserir)'
        WHEN tgenabled = 'O' THEN '⚠️ ATIVO (pode causar timeout!)'
        ELSE 'Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- NOTA: 
-- - O trigger será desabilitado permanentemente até você reabilitá-lo manualmente
-- - Para reabilitar: ALTER TABLE flow_blocks ENABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
-- - Mas NÃO reabilite enquanto estiver inserindo blocos, pois causará timeout
