-- ============================================================================
-- VERIFICAR E FORÇAR SINCRONIZAÇÃO DO ENC001
-- ============================================================================

-- 1. Verificar se o conteúdo "Até logooooo!" está no prompt_voz
SELECT 
    '🔍 VERIFICAÇÃO DE SINCRONIZAÇÃO' as tipo,
    CASE 
        WHEN position('Até logooooo!' IN a.prompt_voz) > 0 THEN
            '✅ SINCRONIZADO - Texto "Até logooooo!" encontrado no prompt_voz'
        ELSE
            '❌ NÃO SINCRONIZADO - Texto "Até logooooo!" NÃO encontrado no prompt_voz'
    END as status,
    substring(
        a.prompt_voz,
        GREATEST(1, position('ENC001' IN LOWER(a.prompt_voz)) - 50),
        LEAST(400, LENGTH(a.prompt_voz) - GREATEST(1, position('ENC001' IN LOWER(a.prompt_voz)) - 50))
    ) as contexto_enc001_no_prompt
FROM assistentes a
WHERE a.id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND a.prompt_voz IS NOT NULL;

-- 2. FORÇAR SINCRONIZAÇÃO: Atualizar o bloco para disparar o trigger
-- Isso vai fazer um UPDATE no flow_blocks, que deve disparar o trigger automaticamente
UPDATE flow_blocks
SET updated_at = NOW()
WHERE block_key = 'ENC001'
  AND flow_id IN (
      SELECT id FROM flows 
      WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  )
  AND id = (
      SELECT id FROM flow_blocks 
      WHERE block_key = 'ENC001'
        AND flow_id IN (
            SELECT id FROM flows 
            WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
        )
      ORDER BY created_at DESC 
      LIMIT 1
  )
RETURNING 
    '✅ UPDATE executado' as resultado,
    block_key,
    content,
    updated_at;

-- 3. Verificar novamente após o UPDATE
SELECT 
    '🔍 VERIFICAÇÃO APÓS UPDATE' as tipo,
    CASE 
        WHEN position('Até logooooo!' IN a.prompt_voz) > 0 THEN
            '✅ SINCRONIZADO - Texto "Até logooooo!" encontrado no prompt_voz'
        ELSE
            '❌ AINDA NÃO SINCRONIZADO - O trigger pode não estar funcionando'
    END as status,
    substring(
        a.prompt_voz,
        GREATEST(1, position('ENC001' IN LOWER(a.prompt_voz)) - 50),
        LEAST(400, LENGTH(a.prompt_voz) - GREATEST(1, position('ENC001' IN LOWER(a.prompt_voz)) - 50))
    ) as contexto_enc001_no_prompt
FROM assistentes a
WHERE a.id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND a.prompt_voz IS NOT NULL;
