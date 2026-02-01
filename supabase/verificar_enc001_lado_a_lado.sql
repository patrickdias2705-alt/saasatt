-- ============================================================================
-- VERIFICAÇÃO LADO A LADO: ENC001 em flow_blocks vs prompt_voz
-- ============================================================================

-- Comparar conteúdo do ENC001 em flow_blocks vs prompt_voz
SELECT 
    '📦 flow_blocks.content' as origem,
    fb.content as conteudo_enc001,
    '---' as separador,
    '📝 prompt_voz (seção ENC001)' as origem_prompt,
    substring(
        a.prompt_voz,
        position('### ENCERRAR [ENC001]' IN LOWER(a.prompt_voz)),
        CASE 
            WHEN position('---' IN substring(a.prompt_voz, position('### ENCERRAR [ENC001]' IN LOWER(a.prompt_voz)))) > 0 THEN
                position('---' IN substring(a.prompt_voz, position('### ENCERRAR [ENC001]' IN LOWER(a.prompt_voz)))) - 1
            ELSE 300
        END
    ) as secao_enc001_no_prompt,
    CASE 
        WHEN position(fb.content IN a.prompt_voz) > 0 THEN
            '✅ SINCRONIZADO'
        ELSE
            '❌ NÃO SINCRONIZADO'
    END as status_sincronizacao
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
JOIN assistentes a ON a.id::text = f.assistente_id::text
WHERE fb.block_key = 'ENC001'
  AND f.assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND a.prompt_voz IS NOT NULL
ORDER BY fb.created_at DESC
LIMIT 1;
