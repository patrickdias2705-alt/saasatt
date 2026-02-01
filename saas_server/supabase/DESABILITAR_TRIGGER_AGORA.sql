-- ============================================================================
-- DESABILITAR TRIGGER QUE CAUSA TIMEOUT
-- Execute este SQL no Supabase SQL Editor AGORA
-- ============================================================================

-- Desabilitar o trigger que sincroniza prompt_voz (causa timeout)
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- Verificar se foi desabilitado
SELECT 
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
    WHEN tgenabled = 'O' THEN '❌ ATIVO (PROBLEMA!)'
    ELSE 'Status desconhecido'
  END as status
FROM pg_trigger 
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- Se ainda estiver ativo, tentar desabilitar novamente
DO $$
BEGIN
  ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
  RAISE NOTICE 'Trigger desabilitado';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Erro ao desabilitar trigger: %', SQLERRM;
END $$;
