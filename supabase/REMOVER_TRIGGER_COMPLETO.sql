-- ============================================================================
-- REMOVER TRIGGER DE SINCRONIZAÇÃO DE PROMPT_VOZ COMPLETAMENTE
-- Execute este SQL no Supabase SQL Editor
-- ============================================================================

-- 1. Desabilitar o trigger primeiro
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 2. Remover o trigger completamente
DROP TRIGGER IF EXISTS trigger_sync_prompt_voz_on_block_change ON flow_blocks;

-- 3. Remover a função que o trigger usa (se existir)
DROP FUNCTION IF EXISTS patch_block_section_in_prompt CASCADE;
DROP FUNCTION IF EXISTS sync_prompt_voz_on_block_change CASCADE;

-- 4. Verificar se foi removido
SELECT 
  tgname as trigger_name,
  '✅ REMOVIDO' as status
FROM pg_trigger 
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- Se não retornar nenhuma linha, o trigger foi removido com sucesso!
