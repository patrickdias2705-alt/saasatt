-- ============================================================================
-- DEBUGAR: Ver formato exato da seção ENC001 no prompt_voz
-- ============================================================================

-- 1. Ver como está a seção ENC001 no prompt_voz (formato exato)
SELECT 
    '📝 FORMATO ATUAL NO prompt_voz' as tipo,
    substring(
        a.prompt_voz,
        GREATEST(1, position('ENC001' IN a.prompt_voz) - 100),
        LEAST(500, LENGTH(a.prompt_voz) - GREATEST(1, position('ENC001' IN a.prompt_voz) - 100))
    ) as secao_enc001_completa,
    -- Verificar se tem o formato esperado
    CASE 
        WHEN position('### ENCERRAR [ENC001]: finalizar' IN a.prompt_voz) > 0 THEN
            '✅ Formato esperado encontrado: "### ENCERRAR [ENC001]: finalizar"'
        WHEN position('### ENCERRAR [ENC001]' IN a.prompt_voz) > 0 THEN
            '⚠️ Formato encontrado: "### ENCERRAR [ENC001]" (sem ": finalizar")'
        WHEN position('ENC001' IN LOWER(a.prompt_voz)) > 0 THEN
            '⚠️ ENC001 encontrado mas formato diferente'
        ELSE
            '❌ ENC001 não encontrado no prompt_voz'
    END as status_formato
FROM assistentes a
WHERE a.id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
  AND a.prompt_voz IS NOT NULL;

-- 2. Ver o que a função format_block_section geraria para o ENC001 atual
SELECT 
    '🔧 O QUE O TRIGGER GERARIA' as tipo,
    format_block_section(
        'ENC001',
        'encerrar',
        'Desculpe pelo engano. Até logooooo!',
        NULL,  -- next_block_key
        NULL,  -- variable_name
        NULL   -- analyze_variable
    ) as secao_formatada_pelo_trigger;

-- 3. Testar a função patch_block_section_in_prompt diretamente
SELECT 
    '🧪 TESTE DA FUNÇÃO PATCH' as tipo,
    CASE 
        WHEN patch_block_section_in_prompt(
            (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'),
            'ENC001',
            'encerrar',
            format_block_section(
                'ENC001',
                'encerrar',
                'Desculpe pelo engano. Até logooooo!',
                NULL,
                NULL,
                NULL
            )
        ) != (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b') THEN
            '✅ Função patch detectou mudança (vai atualizar)'
        ELSE
            '❌ Função patch NÃO detectou mudança (não vai atualizar)'
    END as resultado_teste,
    -- Mostrar preview do que seria o resultado
    substring(
        patch_block_section_in_prompt(
            (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'),
            'ENC001',
            'encerrar',
            format_block_section(
                'ENC001',
                'encerrar',
                'Desculpe pelo engano. Até logooooo!',
                NULL,
                NULL,
                NULL
            )
        ),
        GREATEST(1, position('ENC001' IN patch_block_section_in_prompt(
            (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'),
            'ENC001',
            'encerrar',
            format_block_section(
                'ENC001',
                'encerrar',
                'Desculpe pelo engano. Até logooooo!',
                NULL,
                NULL,
                NULL
            )
        )) - 50),
        300
    ) as preview_resultado_patch;
