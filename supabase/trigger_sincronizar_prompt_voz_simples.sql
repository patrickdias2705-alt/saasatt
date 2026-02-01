-- ============================================================================
-- TRIGGER SIMPLES: Sincronizar prompt_voz quando flow_blocks mudar
-- ============================================================================
-- Versão simplificada que reconstrói o prompt completo a partir dos blocos
-- quando qualquer bloco é modificado.

-- Função para reconstruir prompt completo a partir dos blocos
CREATE OR REPLACE FUNCTION rebuild_prompt_voz_from_blocks(p_flow_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_assistente_id UUID;
    v_prompt_parts TEXT[] := ARRAY[]::TEXT[];
    v_intro_text TEXT;
    v_block RECORD;
    v_block_section TEXT;
    v_prompt_voz_atual TEXT;
BEGIN
    -- Obter assistente_id do flow
    SELECT assistente_id INTO v_assistente_id
    FROM flows
    WHERE id = p_flow_id;
    
    IF v_assistente_id IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Buscar prompt_voz atual para preservar texto introdutório
    SELECT prompt_voz INTO v_prompt_voz_atual
    FROM assistentes
    WHERE id = v_assistente_id;
    
    -- Extrair texto introdutório (antes de "## FLUXO DA CONVERSA")
    IF v_prompt_voz_atual IS NOT NULL THEN
        IF position('## FLUXO DA CONVERSA' IN v_prompt_voz_atual) > 0 THEN
            v_intro_text := substring(v_prompt_voz_atual FROM 1 FOR position('## FLUXO DA CONVERSA' IN v_prompt_voz_atual) - 1);
        ELSE
            v_intro_text := v_prompt_voz_atual;
        END IF;
    END IF;
    
    -- Adicionar texto introdutório se existir
    IF v_intro_text IS NOT NULL AND trim(v_intro_text) != '' THEN
        v_prompt_parts := array_append(v_prompt_parts, trim(v_intro_text));
        v_prompt_parts := array_append(v_prompt_parts, '');
        v_prompt_parts := array_append(v_prompt_parts, '---');
        v_prompt_parts := array_append(v_prompt_parts, '');
    END IF;
    
    -- Adicionar cabeçalho do fluxo
    v_prompt_parts := array_append(v_prompt_parts, '## FLUXO DA CONVERSA');
    v_prompt_parts := array_append(v_prompt_parts, '');
    
    -- Buscar todos os blocos do flow ordenados por order_index
    FOR v_block IN 
        SELECT * FROM flow_blocks
        WHERE flow_id = p_flow_id
        ORDER BY order_index ASC
    LOOP
        -- Formatar seção do bloco
        v_block_section := '';
        
        CASE v_block.block_type
            WHEN 'primeira_mensagem' THEN
                v_block_section := '### ABERTURA DA LIGACAO' || E'\n\n';
                v_block_section := v_block_section || '**Ao iniciar a ligacao, fale:**' || E'\n\n';
                IF v_block.content IS NOT NULL AND v_block.content != '' THEN
                    v_block_section := v_block_section || '"' || v_block.content || '"' || E'\n';
                END IF;
                IF v_block.next_block_key IS NOT NULL THEN
                    v_block_section := v_block_section || E'\n**Depois:** Va para [' || v_block.next_block_key || ']';
                END IF;
                
            WHEN 'aguardar' THEN
                v_block_section := '### AGUARDAR [' || v_block.block_key || ']' || E'\n\n';
                IF v_block.content IS NOT NULL AND v_block.content != '' THEN
                    v_block_section := v_block_section || '**' || v_block.content || '**' || E'\n';
                ELSE
                    v_block_section := v_block_section || '**Escute a resposta do lead.**' || E'\n';
                END IF;
                IF v_block.variable_name IS NOT NULL THEN
                    v_block_section := v_block_section || E'\nSalvar resposta do lead em: `{{{' || v_block.variable_name || '}}}`' || E'\n';
                END IF;
                IF v_block.next_block_key IS NOT NULL THEN
                    v_block_section := v_block_section || E'\n**Depois:** Va para [' || v_block.next_block_key || ']';
                END IF;
                
            WHEN 'mensagem' THEN
                v_block_section := '### MENSAGEM [' || v_block.block_key || ']' || E'\n\n';
                v_block_section := v_block_section || '**Fale:**' || E'\n\n';
                IF v_block.content IS NOT NULL AND v_block.content != '' THEN
                    v_block_section := v_block_section || '"' || v_block.content || '"';
                END IF;
                
            WHEN 'encerrar' THEN
                v_block_section := '### ENCERRAR [' || v_block.block_key || ']: finalizar' || E'\n\n';
                v_block_section := v_block_section || '**Fale antes de encerrar:**' || E'\n\n';
                IF v_block.content IS NOT NULL AND v_block.content != '' THEN
                    v_block_section := v_block_section || '"' || v_block.content || '"';
                END IF;
                
            WHEN 'caminhos' THEN
                v_block_section := '### CAMINHOS [' || v_block.block_key || ']' || E'\n\n';
                IF v_block.analyze_variable IS NOT NULL THEN
                    v_block_section := v_block_section || '**Analisando:** `{{{' || v_block.analyze_variable || '}}}`' || E'\n\n';
                END IF;
                IF v_block.content IS NOT NULL AND v_block.content != '' THEN
                    v_block_section := v_block_section || '**' || v_block.content || '**' || E'\n';
                END IF;
                -- Rotas serão adicionadas depois se necessário
                
            ELSE
                v_block_section := '### [' || v_block.block_key || ']' || E'\n\n';
                IF v_block.content IS NOT NULL AND v_block.content != '' THEN
                    v_block_section := v_block_section || v_block.content;
                END IF;
        END CASE;
        
        -- Adicionar seção ao array
        v_prompt_parts := array_append(v_prompt_parts, v_block_section);
        v_prompt_parts := array_append(v_prompt_parts, '');
        v_prompt_parts := array_append(v_prompt_parts, '---');
        v_prompt_parts := array_append(v_prompt_parts, '');
    END LOOP;
    
    -- Juntar todas as partes
    RETURN array_to_string(v_prompt_parts, E'\n');
END;
$$ LANGUAGE plpgsql;

-- Função do trigger: atualiza prompt_voz quando flow_blocks muda
CREATE OR REPLACE FUNCTION sync_prompt_voz_on_block_change()
RETURNS TRIGGER AS $$
DECLARE
    v_flow_id UUID;
    v_assistente_id UUID;
    v_rebuilt_prompt TEXT;
BEGIN
    -- Determinar flow_id baseado na operação
    IF TG_OP = 'DELETE' THEN
        v_flow_id := OLD.flow_id;
    ELSE
        v_flow_id := NEW.flow_id;
    END IF;
    
    -- Obter assistente_id do flow
    SELECT assistente_id INTO v_assistente_id
    FROM flows
    WHERE id = v_flow_id;
    
    -- Se não tem assistente_id, não fazer nada
    IF v_assistente_id IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Reconstruir prompt completo a partir dos blocos
    v_rebuilt_prompt := rebuild_prompt_voz_from_blocks(v_flow_id);
    
    -- Se conseguiu reconstruir, atualizar prompt_voz
    IF v_rebuilt_prompt IS NOT NULL THEN
        UPDATE assistentes
        SET prompt_voz = v_rebuilt_prompt
        WHERE id = v_assistente_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Criar trigger
DROP TRIGGER IF EXISTS trigger_sync_prompt_voz_on_block_change ON flow_blocks;
CREATE TRIGGER trigger_sync_prompt_voz_on_block_change
    AFTER INSERT OR UPDATE OR DELETE ON flow_blocks
    FOR EACH ROW
    EXECUTE FUNCTION sync_prompt_voz_on_block_change();

-- Comentários
COMMENT ON FUNCTION sync_prompt_voz_on_block_change() IS 
'Sincroniza automaticamente o prompt_voz do assistente quando flow_blocks é modificado. Reconstrói o prompt completo a partir dos blocos.';

COMMENT ON FUNCTION rebuild_prompt_voz_from_blocks(UUID) IS 
'Reconstrói o prompt_voz completo a partir dos blocos de um flow, preservando texto introdutório.';
