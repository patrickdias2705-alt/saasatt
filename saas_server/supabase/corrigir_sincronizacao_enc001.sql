-- ============================================================================
-- CORRIGIR SINCRONIZAÇÃO: Atualizar prompt_voz com conteúdo atual do ENC001
-- ============================================================================

-- ⚠️ SUBSTITUA O ASSISTENTE_ID:
-- 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'

-- 1. Ver conteúdo atual no banco
SELECT 
    '📦 Conteúdo no banco (flow_blocks)' as origem,
    content as conteudo_enc001
FROM flow_blocks
WHERE block_key = 'ENC001'
  AND flow_id IN (
      SELECT id FROM flows 
      WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  )
ORDER BY created_at DESC
LIMIT 1;

-- 2. Ver conteúdo atual no prompt_voz (antes)
SELECT 
    '📝 Conteúdo no prompt_voz (ANTES)' as origem,
    substring(
        prompt_voz,
        position('### ENCERRAR [ENC001]' IN prompt_voz),
        250
    ) as secao_enc001
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND position('### ENCERRAR [ENC001]' IN prompt_voz) > 0;

-- 3. FORÇAR ATUALIZAÇÃO usando a função de patch
UPDATE assistentes
SET prompt_voz = patch_block_section_in_prompt(
    prompt_voz,
    'ENC001',
    'encerrar',
    '### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"' || COALESCE((
    SELECT content 
    FROM flow_blocks 
    WHERE block_key = 'ENC001' 
      AND flow_id IN (
          SELECT id FROM flows 
          WHERE assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
      )
    ORDER BY created_at DESC 
    LIMIT 1
), 'Desculpe pelo engano. Até logo!') || '"'
)
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND prompt_voz IS NOT NULL;

-- 4. Verificar resultado (depois)
SELECT 
    '✅ Conteúdo no prompt_voz (DEPOIS)' as origem,
    substring(
        prompt_voz,
        position('### ENCERRAR [ENC001]' IN prompt_voz),
        250
    ) as secao_enc001_atualizada
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND position('### ENCERRAR [ENC001]' IN prompt_voz) > 0;

-- 5. Verificar se o conteúdo bate
SELECT 
    '🔍 VERIFICAÇÃO FINAL' as teste,
    fb.content as conteudo_no_banco,
    CASE 
        WHEN position(fb.content IN a.prompt_voz) > 0 THEN
            '✅ SINCRONIZADO - Conteúdo bate!'
        ELSE
            '❌ NÃO SINCRONIZADO - Conteúdo não bate'
    END as status,
    substring(
        a.prompt_voz,
        position('### ENCERRAR [ENC001]' IN a.prompt_voz),
        200
    ) as preview_prompt_voz
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
JOIN assistentes a ON a.id::text = f.assistente_id::text
WHERE fb.block_key = 'ENC001'
  AND f.assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
ORDER BY fb.created_at DESC
LIMIT 1;
