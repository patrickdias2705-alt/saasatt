-- ============================================================================
-- TESTE SIMPLES: Verificar se ENC001 está sincronizado
-- ============================================================================
-- ⚠️ SUBSTITUA O ASSISTENTE_ID NAS QUERIES ABAIXO: 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'

-- ============================================================================
-- 1. CONTEÚDO DO ENC001 NO BANCO (flow_blocks)
-- ============================================================================
SELECT 
    '📦 NO BANCO (flow_blocks)' as origem,
    fb.block_key,
    fb.content as conteudo
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.block_key = 'ENC001'
  AND f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA AQUI
ORDER BY fb.created_at DESC
LIMIT 1;

SELECT 
    '📝 NO PROMPT_VOZ' as origem,
    substring(
        prompt_voz,
        position('### ENCERRAR [ENC001]' IN prompt_voz),
        CASE 
            WHEN position(E'\n###' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 100)) > 0 THEN
                position(E'\n###' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 100)) + 100
            WHEN position(E'\n---' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 100)) > 0 THEN
                position(E'\n---' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 100)) + 100
            ELSE 300
        END
    ) as secao_completa
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA AQUI
  AND position('### ENCERRAR [ENC001]' IN prompt_voz) > 0;

-- Comparação direta
WITH bloco_banco AS (
    SELECT fb.content
    FROM flow_blocks fb
    JOIN flows f ON f.id = fb.flow_id
    WHERE fb.block_key = 'ENC001'
      AND f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA AQUI
    ORDER BY fb.created_at DESC
    LIMIT 1
),
prompt_voz AS (
    SELECT prompt_voz
    FROM assistentes
    WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA AQUI
)
SELECT 
    '🔍 COMPARAÇÃO' as teste,
    bb.content as conteudo_no_banco,
    CASE 
        WHEN position(bb.content IN pv.prompt_voz) > 0 THEN
            '✅ CONTEÚDO ENCONTRADO NO PROMPT_VOZ'
        ELSE
            '❌ CONTEÚDO NÃO ENCONTRADO NO PROMPT_VOZ'
    END as status,
    substring(
        pv.prompt_voz,
        position('### ENCERRAR [ENC001]' IN pv.prompt_voz),
        200
    ) as preview_prompt_voz
FROM bloco_banco bb
CROSS JOIN prompt_voz pv;
