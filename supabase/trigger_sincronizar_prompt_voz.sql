-- ============================================================================
-- TRIGGER: Sincronizar prompt_voz do assistente quando flow_blocks mudar
-- ============================================================================
-- Este trigger atualiza automaticamente o prompt_voz do assistente
-- quando um bloco é inserido, atualizado ou deletado em flow_blocks.
-- Mantém apenas a seção específica do bloco atualizada, preservando o resto.

-- Função auxiliar para formatar uma seção de bloco
CREATE OR REPLACE FUNCTION format_block_section(
    p_block_key TEXT,
    p_block_type TEXT,
    p_content TEXT,
    p_next_block_key TEXT,
    p_variable_name TEXT,
    p_analyze_variable TEXT
) RETURNS TEXT AS $$
DECLARE
    v_section TEXT := '';
    v_title TEXT := '';
BEGIN
    -- Determinar título baseado no tipo
    CASE p_block_type
        WHEN 'primeira_mensagem' THEN
            v_title := '### ABERTURA DA LIGACAO';
            v_section := v_title || E'\n\n';
            v_section := v_section || '**Ao iniciar a ligacao, fale:**' || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '"' || p_content || '"' || E'\n';
            END IF;
            IF p_next_block_key IS NOT NULL THEN
                v_section := v_section || E'\n**Depois:** Va para [' || p_next_block_key || ']';
            END IF;
            
        WHEN 'aguardar' THEN
            v_title := '### AGUARDAR [' || p_block_key || ']';
            v_section := v_title || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '**' || p_content || '**' || E'\n';
            ELSE
                v_section := v_section || '**Escute a resposta do lead.**' || E'\n';
            END IF;
            IF p_variable_name IS NOT NULL THEN
                v_section := v_section || E'\nSalvar resposta do lead em: `{{{' || p_variable_name || '}}}`' || E'\n';
            END IF;
            IF p_next_block_key IS NOT NULL THEN
                v_section := v_section || E'\n**Depois:** Va para [' || p_next_block_key || ']';
            END IF;
            
        WHEN 'mensagem' THEN
            v_title := '### MENSAGEM [' || p_block_key || ']';
            v_section := v_title || E'\n\n';
            v_section := v_section || '**Fale:**' || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '"' || p_content || '"';
            END IF;
            
        WHEN 'encerrar' THEN
            v_title := '### ENCERRAR [' || p_block_key || ']: finalizar';
            v_section := v_title || E'\n\n';
            v_section := v_section || '**Fale antes de encerrar:**' || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '"' || p_content || '"';
            END IF;
            
        WHEN 'caminhos' THEN
            v_title := '### CAMINHOS [' || p_block_key || ']';
            v_section := v_title || E'\n\n';
            IF p_analyze_variable IS NOT NULL THEN
                v_section := v_section || '**Analisando:** `{{{' || p_analyze_variable || '}}}`' || E'\n\n';
            END IF;
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '**' || p_content || '**' || E'\n';
            END IF;
            -- Rotas serão adicionadas separadamente se necessário
            
        ELSE
            v_title := '### [' || p_block_key || ']';
            v_section := v_title || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || p_content;
            END IF;
    END CASE;
    
    RETURN v_section;
END;
$$ LANGUAGE plpgsql;

-- Função principal do trigger: atualiza prompt_voz quando flow_blocks muda
CREATE OR REPLACE FUNCTION sync_prompt_voz_on_block_change()
RETURNS TRIGGER AS $$
DECLARE
    v_assistente_id UUID;
    v_prompt_voz TEXT;
    v_block_section TEXT;
    v_section_start INT;
    v_section_end INT;
    v_before_section TEXT;
    v_after_section TEXT;
    v_updated_prompt TEXT;
    v_block_key TEXT;
    v_block_type TEXT;
BEGIN
    -- Obter assistente_id do flow
    IF TG_OP = 'DELETE' THEN
        SELECT assistente_id INTO v_assistente_id 
        FROM flows 
        WHERE id = OLD.flow_id;
        v_block_key := OLD.block_key;
        v_block_type := OLD.block_type;
    ELSE
        SELECT assistente_id INTO v_assistente_id 
        FROM flows 
        WHERE id = NEW.flow_id;
        v_block_key := NEW.block_key;
        v_block_type := NEW.block_type;
    END IF;
    
    -- Se não tem assistente_id, não fazer nada
    IF v_assistente_id IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Buscar prompt_voz atual do assistente
    SELECT prompt_voz INTO v_prompt_voz
    FROM assistentes
    WHERE id = v_assistente_id;
    
    -- Se não tem prompt_voz, não fazer nada (ou criar um novo?)
    IF v_prompt_voz IS NULL OR v_prompt_voz = '' THEN
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Se é DELETE, remover a seção usando regex
    IF TG_OP = 'DELETE' THEN
        -- Padrão regex para encontrar a seção completa (incluindo --- no final)
        -- Procura por ### seguido do tipo e block_key até o próximo ### ou --- ou fim
        CASE v_block_type
            WHEN 'primeira_mensagem' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'###+\\s*ABERTURA\\s+DA\\s+LIGACAO[^#]*?(?=\\n###+|\\n---|$)',
                    '',
                    'g'
                );
            WHEN 'encerrar' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'###+\\s*ENCERRAR\\s*\\[' || v_block_key || E'\\][^#]*?(?=\\n###+|\\n---|$)',
                    '',
                    'g'
                );
            WHEN 'mensagem' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'###+\\s*MENSAGEM\\s*\\[' || v_block_key || E'\\][^#]*?(?=\\n###+|\\n---|$)',
                    '',
                    'g'
                );
            WHEN 'aguardar' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'###+\\s*AGUARDAR\\s*\\[' || v_block_key || E'\\][^#]*?(?=\\n###+|\\n---|$)',
                    '',
                    'g'
                );
            WHEN 'caminhos' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'###+\\s*CAMINHOS\\s*\\[' || v_block_key || E'\\][^#]*?(?=\\n###+|\\n---|$)',
                    '',
                    'g'
                );
            ELSE
                -- Padrão genérico
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'###+[^#]*\\[' || v_block_key || E'\\][^#]*?(?=\\n###+|\\n---|$)',
                    '',
                    'g'
                );
        END CASE;
        
        -- Limpar linhas vazias duplicadas e separadores órfãos
        v_updated_prompt := regexp_replace(v_updated_prompt, E'---\\s*\\n\\s*---', '---', 'g');
        v_updated_prompt := regexp_replace(v_updated_prompt, E'\\n\\n\\n+', E'\n\n', 'g');
        
        -- Se não mudou nada, retornar sem atualizar
        IF v_updated_prompt = v_prompt_voz THEN
            RETURN OLD;
        END IF;
    ELSE
        -- INSERT ou UPDATE: atualizar/criar a seção
        v_block_section := format_block_section(
            v_block_key,
            v_block_type,
            NEW.content,
            NEW.next_block_key,
            NEW.variable_name,
            NEW.analyze_variable
        );
        
        -- Construir padrão regex para encontrar a seção existente
        CASE v_block_type
            WHEN 'primeira_mensagem' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'(###+\\s*ABERTURA\\s+DA\\s+LIGACAO[^#]*?)(?=\\n###+|\\n---|$)',
                    v_block_section,
                    'g'
                );
            WHEN 'encerrar' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'(###+\\s*ENCERRAR\\s*\\[' || v_block_key || E'\\][^#]*?)(?=\\n###+|\\n---|$)',
                    v_block_section,
                    'g'
                );
            WHEN 'mensagem' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'(###+\\s*MENSAGEM\\s*\\[' || v_block_key || E'\\][^#]*?)(?=\\n###+|\\n---|$)',
                    v_block_section,
                    'g'
                );
            WHEN 'aguardar' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'(###+\\s*AGUARDAR\\s*\\[' || v_block_key || E'\\][^#]*?)(?=\\n###+|\\n---|$)',
                    v_block_section,
                    'g'
                );
            WHEN 'caminhos' THEN
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'(###+\\s*CAMINHOS\\s*\\[' || v_block_key || E'\\][^#]*?)(?=\\n###+|\\n---|$)',
                    v_block_section,
                    'g'
                );
            ELSE
                -- Padrão genérico
                v_updated_prompt := regexp_replace(
                    v_prompt_voz,
                    E'(###+[^#]*\\[' || v_block_key || E'\\][^#]*?)(?=\\n###+|\\n---|$)',
                    v_block_section,
                    'g'
                );
        END CASE;
        
        -- Se não encontrou a seção (não mudou), adicionar no final
        IF v_updated_prompt = v_prompt_voz THEN
            IF position('## FLUXO DA CONVERSA' IN v_prompt_voz) = 0 THEN
                v_updated_prompt := v_prompt_voz || E'\n\n## FLUXO DA CONVERSA\n\n';
            ELSE
                v_updated_prompt := v_prompt_voz;
            END IF;
            
            v_updated_prompt := rtrim(v_updated_prompt) || E'\n' || v_block_section || E'\n---\n';
        ELSE
            -- Garantir que há separador --- após a seção se necessário
            IF NOT (v_block_section LIKE '%---%') THEN
                -- Verificar se precisa adicionar --- após a seção
                v_updated_prompt := regexp_replace(
                    v_updated_prompt,
                    '(' || regexp_replace(v_block_section, E'[\\[\\](){}.*+?^$|]', '\\&', 'g') || E')(?!\\n---)',
                    v_block_section || E'\n---',
                    'g'
                );
            END IF;
        END IF;
    END IF;
    
    -- Atualizar prompt_voz do assistente
    UPDATE assistentes
    SET prompt_voz = v_updated_prompt
    WHERE id = v_assistente_id;
    
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
'Sincroniza automaticamente o prompt_voz do assistente quando flow_blocks é modificado';

COMMENT ON FUNCTION format_block_section(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) IS 
'Formata uma seção de bloco no formato esperado pelo parser';
