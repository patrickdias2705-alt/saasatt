-- ============================================================================
-- VERIFICAR E CORRIGIR SINCRONIZAÇÃO DO ENC001
-- ============================================================================

-- ⚠️ SUBSTITUA O ASSISTENTE_ID:
-- 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'

-- 1. Ver o que está no prompt_voz atual
SELECT 
    '📝 PROMPT_VOZ ATUAL' as tipo,
    substring(
        prompt_voz,
        position('### ENCERRAR [ENC001]' IN prompt_voz),
        300
    ) as secao_enc001
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND position('### ENCERRAR [ENC001]' IN prompt_voz) > 0;

-- 2. Ver o que está no banco
SELECT 
    '📦 BANCO (flow_blocks)' as tipo,
    content as conteudo_enc001
FROM flow_blocks
WHERE block_key = 'ENC001'
  AND flow_id IN (
      SELECT id FROM flows 
      WHERE assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  )
ORDER BY created_at DESC
LIMIT 1;

-- 3. FORÇAR ATUALIZAÇÃO MANUAL (se o trigger não estiver funcionando)
UPDATE assistentes
SET prompt_voz = patch_block_section_in_prompt(
    prompt_voz,
    'ENC001',
    'encerrar',
    '### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"' || (
    SELECT content 
    FROM flow_blocks 
    WHERE block_key = 'ENC001' 
      AND flow_id IN (
          SELECT id FROM flows 
          WHERE assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
      )
    ORDER BY created_at DESC 
    LIMIT 1
) || '"'
)
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND prompt_voz IS NOT NULL;

-- 4. Verificar se atualizou
SELECT 
    '✅ APÓS ATUALIZAÇÃO' as tipo,
    substring(
        prompt_voz,
        position('### ENCERRAR [ENC001]' IN prompt_voz),
        300
    ) as secao_enc001_atualizada
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND position('### ENCERRAR [ENC001]' IN prompt_voz) > 0;
