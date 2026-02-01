-- ============================================================================
-- DESABILITAR TRIGGER AGORA - EXECUTE ESTE SQL NO SUPABASE
-- ============================================================================

-- Desabilitar o trigger
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- Verificar status
SELECT 
  tgname,
  CASE WHEN tgenabled = 'D' THEN '✅ DESABILITADO' ELSE '❌ AINDA ATIVO!' END as status
FROM pg_trigger 
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';
