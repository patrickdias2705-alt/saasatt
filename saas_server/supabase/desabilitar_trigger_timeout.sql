-- ============================================================================
-- DESABILITAR TRIGGER QUE CAUSA TIMEOUT
-- ============================================================================
-- Execute este script no Supabase SQL Editor para desabilitar o trigger
-- que está causando timeout ao inserir blocos

-- Desabilitar trigger
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- Verificar se foi desabilitado
SELECT 
    '✅ Trigger desabilitado' as status,
    tgname as nome_trigger,
    CASE 
        WHEN tgenabled = 'D' THEN 'DESABILITADO'
        WHEN tgenabled = 'O' THEN 'ATIVO'
        ELSE 'Status desconhecido'
    END as status_trigger
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- NOTA: Após desabilitar, o código Python conseguirá inserir blocos sem timeout
-- Para reabilitar depois: ALTER TABLE flow_blocks ENABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
