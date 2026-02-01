-- ============================================================================
-- TRIGGER CIRÚRGICO: Atualiza apenas a seção específica do bloco modificado
-- ============================================================================
-- Quando um bloco é modificado, atualiza APENAS aquela seção no prompt_voz,
-- mantendo todo o resto do prompt intacto.

-- Função para formatar uma seção de bloco
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
BEGIN
    CASE p_block_type
        WHEN 'primeira_mensagem' THEN
            v_section := '### ABERTURA DA LIGACAO' || E'\n\n';
            v_section := v_section || '**Ao iniciar a ligacao, fale:**' || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '"' || replace(p_content, '"', '') || '"' || E'\n';
            END IF;
            IF p_next_block_key IS NOT NULL THEN
                v_section := v_section || E'\n**Depois:** Va para [' || p_next_block_key || ']';
            END IF;
            
        WHEN 'aguardar' THEN
            v_section := '### AGUARDAR [' || p_block_key || ']' || E'\n\n';
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
            v_section := '### MENSAGEM [' || p_block_key || ']' || E'\n\n';
            v_section := v_section || '**Fale:**' || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '"' || replace(p_content, '"', '') || '"';
            END IF;
            
        WHEN 'encerrar' THEN
            v_section := '### ENCERRAR [' || p_block_key || ']: finalizar' || E'\n\n';
            v_section := v_section || '**Fale antes de encerrar:**' || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '"' || replace(p_content, '"', '') || '"';
            END IF;
            
        WHEN 'caminhos' THEN
            v_section := '### CAMINHOS [' || p_block_key || ']' || E'\n\n';
            IF p_analyze_variable IS NOT NULL THEN
                v_section := v_section || '**Analisando:** `{{{' || p_analyze_variable || '}}}`' || E'\n\n';
            END IF;
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || '**' || p_content || '**' || E'\n';
            END IF;
            
        ELSE
            v_section := '### [' || p_block_key || ']' || E'\n\n';
            IF p_content IS NOT NULL AND p_content != '' THEN
                v_section := v_section || p_content;
            END IF;
    END CASE;
    
    RETURN v_section;
END;
$$ LANGUAGE plpgsql;

-- Função para encontrar e substituir apenas uma seção específica (método robusto)
CREATE OR REPLACE FUNCTION patch_block_section_in_prompt(
    p_prompt TEXT,
    p_block_key TEXT,
    p_block_type TEXT,
    p_new_section TEXT
) RETURNS TEXT AS $$
DECLARE
    v_section_start INT := 0;
    v_section_end INT;
    v_before TEXT;
    v_after TEXT;
    v_search_text TEXT;
    v_remaining TEXT;
    v_updated_prompt TEXT;
BEGIN
    -- Encontrar início da seção usando position (mais confiável que regex)
    CASE p_block_type
        WHEN 'primeira_mensagem' THEN
            v_search_text := '### ABERTURA DA LIGACAO';
            v_section_start := position(v_search_text IN p_prompt);
        WHEN 'encerrar' THEN
            -- Tentar diferentes variações do título
            v_search_text := '### ENCERRAR [' || p_block_key || ']: finalizar';
            v_section_start := position(v_search_text IN p_prompt);
            -- Se não encontrou, tentar sem ": finalizar"
            IF v_section_start = 0 THEN
                v_search_text := '### ENCERRAR [' || p_block_key || ']';
                v_section_start := position(v_search_text IN p_prompt);
            END IF;
            -- Se ainda não encontrou, tentar case-insensitive
            IF v_section_start = 0 THEN
                v_section_start := position(lower(v_search_text) IN lower(p_prompt));
            END IF;
        WHEN 'mensagem' THEN
            v_search_text := '### MENSAGEM [' || p_block_key || ']';
            v_section_start := position(v_search_text IN p_prompt);
        WHEN 'aguardar' THEN
            v_search_text := '### AGUARDAR [' || p_block_key || ']';
            v_section_start := position(v_search_text IN p_prompt);
        WHEN 'caminhos' THEN
            v_search_text := '### CAMINHOS [' || p_block_key || ']';
            v_section_start := position(v_search_text IN p_prompt);
        ELSE
            -- Tentar encontrar por block_key genérico
            v_search_text := '[' || p_block_key || ']';
            v_section_start := position(v_search_text IN p_prompt);
            -- Se encontrou, procurar ### antes
            IF v_section_start > 0 THEN
                v_before := substring(p_prompt FROM 1 FOR v_section_start - 1);
                v_section_start := position(E'\n###' IN reverse(v_before));
                IF v_section_start > 0 THEN
                    v_section_start := length(v_before) - v_section_start - length(E'\n###') + 2;
                ELSE
                    v_section_start := 0;
                END IF;
            END IF;
    END CASE;
    
    -- Se encontrou a seção, substituir
    IF v_section_start > 0 THEN
        -- Encontrar fim da seção (próximo ### ou ---)
        -- Procurar após o início da seção (pular pelo menos 100 chars para evitar pegar o título)
        v_remaining := substring(p_prompt FROM v_section_start + 100);
        
        -- Procurar próximo ### (início de outra seção)
        v_section_end := position(E'\n###' IN v_remaining);
        
        -- Se não encontrou ###, procurar --- (separador)
        IF v_section_end = 0 THEN
            v_section_end := position(E'\n---' IN v_remaining);
        END IF;
        
        -- Se ainda não encontrou, procurar por --- seguido de quebra de linha
        IF v_section_end = 0 THEN
            v_section_end := position(E'---\n' IN v_remaining);
        END IF;
        
        -- Calcular posição final
        IF v_section_end > 0 THEN
            v_section_end := v_section_start + 100 + v_section_end - 1;
        ELSE
            -- Não encontrou fim, vai até o final do texto
            v_section_end := length(p_prompt);
        END IF;
        
        -- Extrair partes antes e depois
        v_before := substring(p_prompt FROM 1 FOR v_section_start - 1);
        v_after := substring(p_prompt FROM v_section_end);
        
        -- Se p_new_section está vazio (DELETE), remover a seção
        IF p_new_section IS NULL OR p_new_section = '' THEN
            -- Remover a seção e limpar separadores
            v_updated_prompt := rtrim(v_before);
            IF v_after IS NOT NULL AND v_after != '' THEN
                -- Remover --- se estiver logo após a seção removida
                IF v_after LIKE E'---%' THEN
                    v_after := regexp_replace(v_after, E'^---\\s*\\n?', '', 'g');
                END IF;
                v_updated_prompt := v_updated_prompt || E'\n' || ltrim(v_after);
            END IF;
        ELSE
            -- Substituir a seção
            v_updated_prompt := rtrim(v_before) || E'\n' || p_new_section;
            
            -- Adicionar conteúdo após, preservando separadores
            IF v_after IS NOT NULL AND v_after != '' THEN
                -- Se a nova seção não termina com --- e o after não começa com ---, adicionar separador
                IF NOT (p_new_section LIKE '%---%') AND NOT (trim(v_after) LIKE '---%') THEN
                    v_updated_prompt := v_updated_prompt || E'\n---\n';
                END IF;
                v_updated_prompt := v_updated_prompt || ltrim(v_after);
            END IF;
        END IF;
        
        -- Garantir que retorna algo válido
        IF v_updated_prompt IS NULL THEN
            RETURN p_prompt;
        END IF;
        
        RETURN v_updated_prompt;
    END IF;
    
    -- Seção não encontrada: adicionar no final (seção nova)
    IF p_new_section IS NULL OR p_new_section = '' THEN
        -- Se é DELETE e não encontrou, não fazer nada
        RETURN p_prompt;
    END IF;
    
    -- Adicionar cabeçalho se não existir
    IF position('## FLUXO DA CONVERSA' IN p_prompt) = 0 THEN
        v_updated_prompt := p_prompt || E'\n\n## FLUXO DA CONVERSA\n\n';
    ELSE
        v_updated_prompt := p_prompt;
    END IF;
    
    -- Adicionar nova seção no final
    v_updated_prompt := rtrim(v_updated_prompt) || E'\n' || p_new_section || E'\n---\n';
    
    -- Garantir que retorna algo válido
    IF v_updated_prompt IS NULL THEN
        RETURN p_prompt;
    END IF;
    
    RETURN v_updated_prompt;
END;
$$ LANGUAGE plpgsql;

-- Função principal do trigger
CREATE OR REPLACE FUNCTION sync_prompt_voz_on_block_change()
RETURNS TRIGGER AS $$
DECLARE
    v_assistente_id UUID;
    v_prompt_voz TEXT;
    v_block_section TEXT;
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
    
    -- Se não tem prompt_voz, não fazer nada (mas logar para debug)
    IF v_prompt_voz IS NULL OR v_prompt_voz = '' THEN
        RAISE NOTICE 'sync_prompt_voz: Assistente % não tem prompt_voz, pulando sincronização', v_assistente_id;
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    -- Log para debug
    RAISE NOTICE 'sync_prompt_voz: Processando % do bloco % (tipo: %)', TG_OP, v_block_key, v_block_type;
    
    -- Se é DELETE, remover a seção
    IF TG_OP = 'DELETE' THEN
        -- Usar função de patch para remover (passar string vazia)
        v_updated_prompt := patch_block_section_in_prompt(
            v_prompt_voz,
            v_block_key,
            v_block_type,
            ''  -- String vazia = remover
        );
        
        -- Limpar linhas vazias duplicadas e separadores órfãos
        v_updated_prompt := regexp_replace(v_updated_prompt, E'---\\s*\\n\\s*---', '---', 'g');
        v_updated_prompt := regexp_replace(v_updated_prompt, E'\\n\\n\\n+', E'\n\n', 'g');
    ELSE
        -- INSERT ou UPDATE: formatar nova seção e substituir
        v_block_section := format_block_section(
            v_block_key,
            v_block_type,
            NEW.content,
            NEW.next_block_key,
            NEW.variable_name,
            NEW.analyze_variable
        );
        
        -- Fazer patch cirúrgico: substituir apenas a seção específica
        v_updated_prompt := patch_block_section_in_prompt(
            v_prompt_voz,
            v_block_key,
            v_block_type,
            v_block_section
        );
    END IF;
    
    -- Atualizar prompt_voz do assistente apenas se mudou
    IF v_updated_prompt != v_prompt_voz THEN
        UPDATE assistentes
        SET prompt_voz = v_updated_prompt
        WHERE id = v_assistente_id;
        
        RAISE NOTICE 'sync_prompt_voz: ✅ prompt_voz atualizado para assistente % (bloco: %)', v_assistente_id, v_block_key;
    ELSE
        RAISE NOTICE 'sync_prompt_voz: ⚠️ prompt_voz não mudou para assistente % (bloco: %) - pode indicar que seção não foi encontrada', v_assistente_id, v_block_key;
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

-- IMPORTANTE: O trigger funciona quando há INSERT, UPDATE ou DELETE direto em flow_blocks
-- Se o código Python faz DELETE todos + INSERT todos, o trigger será executado
-- mas pode haver problemas se muitos blocos são inseridos de uma vez
-- Nesse caso, considere usar um trigger AFTER STATEMENT em vez de FOR EACH ROW

-- Comentários
COMMENT ON FUNCTION sync_prompt_voz_on_block_change() IS 
'Sincroniza automaticamente o prompt_voz do assistente quando flow_blocks é modificado. Atualiza APENAS a seção específica do bloco, mantendo o resto intacto.';

COMMENT ON FUNCTION patch_block_section_in_prompt(TEXT, TEXT, TEXT, TEXT) IS 
'Faz patch cirúrgico: encontra e substitui apenas a seção específica de um bloco no prompt, mantendo o resto intacto.';

COMMENT ON FUNCTION format_block_section(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) IS 
'Formata uma seção de bloco no formato esperado pelo parser.';
