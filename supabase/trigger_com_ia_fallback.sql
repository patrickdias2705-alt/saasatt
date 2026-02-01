-- ============================================================================
-- TRIGGER COM FALLBACK PARA IA
-- ============================================================================
-- Este trigger tenta primeiro usar SQL, e se falhar, chama a API com IA
-- 
-- PRÉ-REQUISITOS:
-- 1. Instalar extensão pg_net no Supabase
-- 2. Configurar ANTHROPIC_API_KEY ou OPENAI_API_KEY no servidor FastAPI
-- 3. Servidor FastAPI rodando e acessível
--
-- Para instalar pg_net:
--   CREATE EXTENSION IF NOT EXISTS pg_net;

-- Função que chama a API de IA como fallback
CREATE OR REPLACE FUNCTION call_ai_patch_api(
    p_assistente_id UUID,
    p_block_key TEXT,
    p_block_type TEXT,
    p_new_content TEXT,
    p_next_block_key TEXT DEFAULT NULL,
    p_variable_name TEXT DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    v_api_url TEXT := 'http://localhost:8080/api/flows/ai-patch-prompt';  -- Ajuste se necessário
    v_request_body JSONB;
    v_response JSONB;
    v_updated_prompt TEXT;
BEGIN
    -- Construir body da requisição
    v_request_body := jsonb_build_object(
        'assistente_id', p_assistente_id::text,
        'block_key', p_block_key,
        'block_type', p_block_type,
        'new_content', p_new_content,
        'provider', 'anthropic',
        'next_block_key', p_next_block_key,
        'variable_name', p_variable_name
    );
    
    -- Chamar API via pg_net
    SELECT content INTO v_response
    FROM net.http_post(
        url := v_api_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json'
        ),
        body := v_request_body::text
    );
    
    -- Extrair prompt atualizado da resposta
    IF v_response->>'success' = 'true' THEN
        v_updated_prompt := v_response->>'updated_prompt';
        RAISE NOTICE '✅ IA patch bem-sucedido para bloco %', p_block_key;
        RETURN v_updated_prompt;
    ELSE
        RAISE WARNING '❌ IA patch falhou: %', v_response->>'error';
        RETURN NULL;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '❌ Erro ao chamar API de IA: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger modificado com fallback para IA
CREATE OR REPLACE FUNCTION sync_prompt_voz_on_block_change_with_ai_fallback()
RETURNS TRIGGER AS $$
DECLARE
    v_assistente_id UUID;
    v_prompt_voz TEXT;
    v_block_section TEXT;
    v_updated_prompt TEXT;
    v_block_key TEXT;
    v_block_type TEXT;
    v_sql_success BOOLEAN := FALSE;
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
    
    -- Se não tem prompt_voz, não fazer nada
    IF v_prompt_voz IS NULL OR v_prompt_voz = '' THEN
        RAISE NOTICE 'sync_prompt_voz: Assistente % não tem prompt_voz, pulando sincronização', v_assistente_id;
        RETURN COALESCE(NEW, OLD);
    END IF;
    
    RAISE NOTICE 'sync_prompt_voz: Processando % do bloco % (tipo: %)', TG_OP, v_block_key, v_block_type;
    
    -- TENTAR PRIMEIRO COM SQL (método atual)
    BEGIN
        IF TG_OP = 'DELETE' THEN
            v_updated_prompt := patch_block_section_in_prompt(
                v_prompt_voz,
                v_block_key,
                v_block_type,
                ''  -- String vazia = remover
            );
        ELSE
            v_block_section := format_block_section(
                v_block_key,
                v_block_type,
                NEW.content,
                NEW.next_block_key,
                NEW.variable_name,
                NEW.analyze_variable
            );
            
            v_updated_prompt := patch_block_section_in_prompt(
                v_prompt_voz,
                v_block_key,
                v_block_type,
                v_block_section
            );
        END IF;
        
        -- Verificar se o SQL funcionou (prompt mudou)
        IF v_updated_prompt != v_prompt_voz THEN
            v_sql_success := TRUE;
            RAISE NOTICE '✅ SQL patch bem-sucedido para bloco %', v_block_key;
        ELSE
            RAISE NOTICE '⚠️ SQL patch não detectou mudança, tentando IA...';
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '❌ Erro no SQL patch: %, tentando IA...', SQLERRM;
        v_sql_success := FALSE;
    END;
    
    -- SE SQL FALHOU OU NÃO DETECTOU MUDANÇA, USAR IA COMO FALLBACK
    IF NOT v_sql_success THEN
        IF TG_OP != 'DELETE' THEN
            v_updated_prompt := call_ai_patch_api(
                v_assistente_id,
                v_block_key,
                v_block_type,
                NEW.content,
                NEW.next_block_key,
                NEW.variable_name
            );
            
            -- Se IA também falhou, manter prompt original
            IF v_updated_prompt IS NULL THEN
                RAISE WARNING '⚠️ Ambos SQL e IA falharam, mantendo prompt original';
                v_updated_prompt := v_prompt_voz;
            END IF;
        ELSE
            -- Para DELETE, manter prompt original se IA não disponível
            v_updated_prompt := v_prompt_voz;
        END IF;
    END IF;
    
    -- Atualizar prompt_voz do assistente apenas se mudou
    IF v_updated_prompt != v_prompt_voz THEN
        UPDATE assistentes
        SET prompt_voz = v_updated_prompt
        WHERE id = v_assistente_id;
        
        RAISE NOTICE '✅ prompt_voz atualizado para assistente % (bloco: %)', v_assistente_id, v_block_key;
    ELSE
        RAISE NOTICE '⚠️ prompt_voz não mudou para assistente % (bloco: %)', v_assistente_id, v_block_key;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Criar trigger (substitui o anterior)
DROP TRIGGER IF EXISTS trigger_sync_prompt_voz_on_block_change ON flow_blocks;
CREATE TRIGGER trigger_sync_prompt_voz_on_block_change
    AFTER INSERT OR UPDATE OR DELETE ON flow_blocks
    FOR EACH ROW
    EXECUTE FUNCTION sync_prompt_voz_on_block_change_with_ai_fallback();

-- Comentários
COMMENT ON FUNCTION call_ai_patch_api IS 
'Chama a API FastAPI para fazer patch com IA quando o método SQL falha';

COMMENT ON FUNCTION sync_prompt_voz_on_block_change_with_ai_fallback IS 
'Trigger que tenta SQL primeiro, e usa IA como fallback se necessário';
