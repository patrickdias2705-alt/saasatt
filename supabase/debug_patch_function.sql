-- ============================================================================
-- DEBUG: Testar função patch_block_section_in_prompt passo a passo
-- ============================================================================

-- Substitua os valores abaixo:
DO $$
DECLARE
    v_assistente_id UUID := 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';
    v_block_key TEXT := 'ENC001';
    v_prompt_voz TEXT;
    v_section_start INT;
    v_search_text TEXT;
    v_resultado TEXT;
BEGIN
    -- Buscar prompt_voz
    SELECT prompt_voz INTO v_prompt_voz
    FROM assistentes
    WHERE id = v_assistente_id;
    
    IF v_prompt_voz IS NULL THEN
        RAISE NOTICE '❌ prompt_voz não encontrado';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ prompt_voz encontrado (tamanho: %)', length(v_prompt_voz);
    
    -- Tentar encontrar a seção ENC001
    v_search_text := '### ENCERRAR [' || v_block_key || ']: finalizar';
    v_section_start := position(v_search_text IN v_prompt_voz);
    RAISE NOTICE 'Busca 1: "%" -> posição: %', v_search_text, v_section_start;
    
    IF v_section_start = 0 THEN
        v_search_text := '### ENCERRAR [' || v_block_key || ']';
        v_section_start := position(v_search_text IN v_prompt_voz);
        RAISE NOTICE 'Busca 2: "%" -> posição: %', v_search_text, v_section_start;
    END IF;
    
    IF v_section_start = 0 THEN
        -- Tentar case-insensitive
        v_section_start := position(lower('### ENCERRAR [' || v_block_key || ']') IN lower(v_prompt_voz));
        RAISE NOTICE 'Busca 3 (case-insensitive): posição: %', v_section_start;
    END IF;
    
    IF v_section_start > 0 THEN
        RAISE NOTICE '✅ Seção encontrada na posição %', v_section_start;
        RAISE NOTICE 'Preview da seção: %', substring(v_prompt_voz FROM v_section_start FOR 200);
        
        -- Testar a função completa
        v_resultado := patch_block_section_in_prompt(
            v_prompt_voz,
            v_block_key,
            'encerrar',
            '### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logooooo!"'
        );
        
        IF v_resultado IS NULL THEN
            RAISE NOTICE '❌ Função retornou NULL';
        ELSE
            RAISE NOTICE '✅ Função retornou resultado (tamanho: %)', length(v_resultado);
            RAISE NOTICE 'Preview do resultado: %', substring(v_resultado FROM v_section_start FOR 200);
        END IF;
    ELSE
        RAISE NOTICE '❌ Seção não encontrada no prompt_voz';
        RAISE NOTICE 'Preview do prompt_voz: %', substring(v_prompt_voz FROM 1 FOR 500);
    END IF;
END $$;
