-- ============================================================================
-- FORÇAR ATUALIZAÇÃO: Atualizar prompt_voz manualmente para um bloco específico
-- ============================================================================
-- Use este SQL para forçar a atualização do prompt_voz quando o trigger não funcionar

-- ⚠️ SUBSTITUA OS VALORES ABAIXO:
-- - assistente_id: ID do seu assistente
-- - block_key: Chave do bloco (ex: ENC001)
-- - novo_conteudo: O novo conteúdo que você quer

DO $$
DECLARE
    v_assistente_id UUID := 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';  -- ⚠️ SUBSTITUA
    v_block_key TEXT := 'ENC001';  -- ⚠️ SUBSTITUA
    v_novo_conteudo TEXT := 'Desculpe pelo engano. Até logooooo!';  -- ⚠️ SUBSTITUA
    v_prompt_voz TEXT;
    v_updated_prompt TEXT;
    v_block_section TEXT;
BEGIN
    -- Buscar prompt_voz atual
    SELECT prompt_voz INTO v_prompt_voz
    FROM assistentes
    WHERE id = v_assistente_id;
    
    IF v_prompt_voz IS NULL THEN
        RAISE NOTICE 'Assistente não encontrado ou sem prompt_voz';
        RETURN;
    END IF;
    
    -- Formatar nova seção
    v_block_section := '### ENCERRAR [' || v_block_key || ']: finalizar' || E'\n\n';
    v_block_section := v_block_section || '**Fale antes de encerrar:**' || E'\n\n';
    v_block_section := v_block_section || '"' || v_novo_conteudo || '"';
    
    -- Aplicar patch
    v_updated_prompt := patch_block_section_in_prompt(
        v_prompt_voz,
        v_block_key,
        'encerrar',
        v_block_section
    );
    
    -- Atualizar
    UPDATE assistentes
    SET prompt_voz = v_updated_prompt
    WHERE id = v_assistente_id;
    
    RAISE NOTICE '✅ prompt_voz atualizado!';
    RAISE NOTICE 'Tamanho antes: %, depois: %', length(v_prompt_voz), length(v_updated_prompt);
END $$;

-- Verificar resultado
SELECT 
    id,
    substring(prompt_voz, position('### ENCERRAR [ENC001]' IN prompt_voz), 200) as secao_enc001_atualizada
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';
