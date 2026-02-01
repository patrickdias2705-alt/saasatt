-- ============================================================================
-- DIAGNÓSTICO COMPLETO: Verificar trigger e sincronização ENC001
-- ============================================================================

-- 1. Verificar se o trigger existe e está ativo
SELECT 
    '🔍 STATUS DO TRIGGER' as verificacao,
    tgname as nome_trigger,
    tgenabled as ativo,
    CASE 
        WHEN tgenabled = 'O' THEN '✅ Trigger ATIVO'
        WHEN tgenabled = 'D' THEN '❌ Trigger DESABILITADO'
        ELSE '⚠️ Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- 2. Ver conteúdo atual em flow_blocks
SELECT 
    '📦 CONTEÚDO EM flow_blocks' as origem,
    fb.block_key,
    fb.block_type,
    fb.content,
    fb.created_at
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.block_key = 'ENC001'
  AND f.assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
ORDER BY fb.created_at DESC
LIMIT 1;

-- 3. Ver seção ENC001 no prompt_voz (extrair a seção completa)
SELECT 
    '📝 SEÇÃO ENC001 NO prompt_voz' as origem,
    substring(
        a.prompt_voz,
        position('### ENCERRAR [ENC001]' IN LOWER(a.prompt_voz)),
        LEAST(
            COALESCE(
                NULLIF(position('---' IN substring(a.prompt_voz, position('### ENCERRAR [ENC001]' IN LOWER(a.prompt_voz)) + 1)), 0),
                300
            ),
            300
        )
    ) as secao_enc001
FROM assistentes a
WHERE a.id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND position('### ENCERRAR [ENC001]' IN LOWER(a.prompt_voz)) > 0;

-- 4. Comparação lado a lado
SELECT 
    '🔍 COMPARAÇÃO' as tipo,
    fb.content as conteudo_flow_blocks,
    substring(
        a.prompt_voz,
        position('### ENCERRAR [ENC001]' IN LOWER(a.prompt_voz)),
        200
    ) as preview_prompt_voz,
    CASE 
        WHEN position(fb.content IN a.prompt_voz) > 0 THEN
            '✅ SINCRONIZADO - Conteúdo encontrado no prompt_voz'
        ELSE
            '❌ NÃO SINCRONIZADO - Conteúdo NÃO encontrado no prompt_voz'
    END as status
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
JOIN assistentes a ON a.id::text = f.assistente_id::text
WHERE fb.block_key = 'ENC001'
  AND f.assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
ORDER BY fb.created_at DESC
LIMIT 1;

-- 5. TESTE: Forçar atualização manual usando a função de patch
-- (Descomente para executar)
/*
UPDATE flow_blocks
SET content = content  -- Simula um UPDATE para disparar o trigger
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
  );
*/
