-- ============================================================================
-- TRIGGER ALTERNATIVO: Executa APÓS toda a transação (não por linha)
-- ============================================================================
-- Este trigger é melhor quando o código faz DELETE todos + INSERT todos
-- porque executa uma vez após toda a operação, não para cada linha

-- Função que reconstrói o prompt completo após mudanças em blocos
CREATE OR REPLACE FUNCTION sync_prompt_voz_after_statement()
RETURNS TRIGGER AS $$
DECLARE
    v_flow_id UUID;
    v_assistente_id UUID;
    v_prompt_voz TEXT;
    v_rebuilt_prompt TEXT;
    v_intro_text TEXT;
    v_block RECORD;
    v_block_section TEXT;
    v_prompt_parts TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Obter flow_id da tabela temporária ou do contexto
    -- Como é AFTER STATEMENT, precisamos buscar todos os flows afetados
    FOR v_flow_id IN 
        SELECT DISTINCT flow_id 
        FROM flow_blocks 
        WHERE flow_id IN (
            SELECT DISTINCT flow_id 
            FROM flow_blocks 
            WHERE created_at > NOW() - INTERVAL '1 minute'
               OR updated_at > NOW() - INTERVAL '1 minute'
        )
    LOOP
        -- Obter assistente_id do flow
        SELECT assistente_id INTO v_assistente_id
        FROM flows
        WHERE id = v_flow_id;
        
        IF v_assistente_id IS NULL THEN
            CONTINUE;
        END IF;
        
        -- Buscar prompt_voz atual para preservar texto introdutório
        SELECT prompt_voz INTO v_prompt_voz
        FROM assistentes
        WHERE id = v_assistente_id;
        
        IF v_prompt_voz IS NULL OR v_prompt_voz = '' THEN
            CONTINUE;
        END IF;
        
        -- Extrair texto introdutório
        IF position('## FLUXO DA CONVERSA' IN v_prompt_voz) > 0 THEN
            v_intro_text := substring(v_prompt_voz FROM 1 FOR position('## FLUXO DA CONVERSA' IN v_prompt_voz) - 1);
        ELSE
            v_intro_text := v_prompt_voz;
        END IF;
        
        -- Limpar array
        v_prompt_parts := ARRAY[]::TEXT[];
        
        -- Adicionar texto introdutório
        IF v_intro_text IS NOT NULL AND trim(v_intro_text) != '' THEN
            v_prompt_parts := array_append(v_prompt_parts, trim(v_intro_text));
            v_prompt_parts := array_append(v_prompt_parts, '');
            v_prompt_parts := array_append(v_prompt_parts, '---');
            v_prompt_parts := array_append(v_prompt_parts, '');
        END IF;
        
        -- Adicionar cabeçalho
        v_prompt_parts := array_append(v_prompt_parts, '## FLUXO DA CONVERSA');
        v_prompt_parts := array_append(v_prompt_parts, '');
        
        -- Buscar todos os blocos do flow e reconstruir
        FOR v_block IN 
            SELECT * FROM flow_blocks
            WHERE flow_id = v_flow_id
            ORDER BY order_index ASC
        LOOP
            -- Formatar seção usando a função existente
            v_block_section := format_block_section(
                v_block.block_key,
                v_block.block_type,
                v_block.content,
                v_block.next_block_key,
                v_block.variable_name,
                v_block.analyze_variable
            );
            
            v_prompt_parts := array_append(v_prompt_parts, v_block_section);
            v_prompt_parts := array_append(v_prompt_parts, '');
            v_prompt_parts := array_append(v_prompt_parts, '---');
            v_prompt_parts := array_append(v_prompt_parts, '');
        END LOOP;
        
        -- Juntar e atualizar
        v_rebuilt_prompt := array_to_string(v_prompt_parts, E'\n');
        
        UPDATE assistentes
        SET prompt_voz = v_rebuilt_prompt
        WHERE id = v_assistente_id;
        
        RAISE NOTICE 'sync_prompt_voz_after_statement: ✅ prompt_voz atualizado para assistente % (flow: %)', v_assistente_id, v_flow_id;
    END LOOP;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Criar trigger AFTER STATEMENT (executa uma vez após toda a transação)
DROP TRIGGER IF EXISTS trigger_sync_prompt_voz_after_statement ON flow_blocks;
CREATE TRIGGER trigger_sync_prompt_voz_after_statement
    AFTER INSERT OR UPDATE OR DELETE ON flow_blocks
    FOR EACH STATEMENT
    EXECUTE FUNCTION sync_prompt_voz_after_statement();

-- NOTA: Este trigger reconstrói o prompt COMPLETO, não faz patch parcial
-- Mas é mais confiável quando há muitas operações de uma vez
