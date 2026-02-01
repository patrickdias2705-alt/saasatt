-- ============================================================================
-- FORÇAR SINCRONIZAÇÃO MANUAL DO ENC001
-- ============================================================================
-- Este script atualiza diretamente o prompt_voz usando a função de patch
-- Use se o trigger não estiver funcionando

-- 1. Ver conteúdo atual antes da atualização
SELECT 
    '📝 ANTES DA ATUALIZAÇÃO' as etapa,
    substring(
        a.prompt_voz,
        GREATEST(1, position('ENC001' IN LOWER(a.prompt_voz)) - 50),
        300
    ) as secao_enc001_antes
FROM assistentes a
WHERE a.id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';

-- 2. ATUALIZAR usando a função de patch diretamente
UPDATE assistentes
SET prompt_voz = patch_block_section_in_prompt(
    prompt_voz,
    'ENC001',
    'encerrar',
    format_block_section(
        'ENC001',
        'encerrar',
        (SELECT content FROM flow_blocks 
         WHERE block_key = 'ENC001' 
           AND flow_id IN (
               SELECT id FROM flows 
               WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
           )
         ORDER BY created_at DESC 
         LIMIT 1),
        NULL,  -- next_block_key
        NULL,  -- variable_name
        NULL   -- analyze_variable
    )
)
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND prompt_voz IS NOT NULL
RETURNING 
    '✅ ATUALIZAÇÃO EXECUTADA' as resultado,
    CASE 
        WHEN position('Até logooooo!' IN prompt_voz) > 0 THEN
            '✅ Texto "Até logooooo!" encontrado no prompt_voz'
        ELSE
            '❌ Texto "Até logooooo!" NÃO encontrado'
    END as verificacao;

-- 3. Ver conteúdo após a atualização
SELECT 
    '📝 DEPOIS DA ATUALIZAÇÃO' as etapa,
    substring(
        a.prompt_voz,
        GREATEST(1, position('ENC001' IN LOWER(a.prompt_voz)) - 50),
        300
    ) as secao_enc001_depois,
    CASE 
        WHEN position('Até logooooo!' IN a.prompt_voz) > 0 THEN
            '✅ SINCRONIZADO - Texto encontrado!'
        ELSE
            '❌ AINDA NÃO SINCRONIZADO'
    END as status_final
FROM assistentes a
WHERE a.id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';
