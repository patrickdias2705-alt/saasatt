-- ============================================================================
-- INSERIR BLOCOS AUTOMATICAMENTE - EXECUTE ESTE SCRIPT AGORA
-- ============================================================================
-- Este script:
-- 1. Desabilita o trigger que causa timeout
-- 2. Busca o prompt_voz do assistente
-- 3. Extrai e insere os blocos automaticamente
-- 4. Reabilita o trigger

-- ⚠️ SUBSTITUA O ASSISTENTE_ID SE NECESSÁRIO:
-- 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'

-- 1. DESABILITAR TRIGGER (resolve timeout)
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 2. Buscar flow_id e prompt_voz
DO $$
DECLARE
    v_assistente_id UUID := 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';
    v_flow_id UUID;
    v_tenant_id UUID;
    v_prompt_voz TEXT;
    v_pm_content TEXT;
    v_ag_content TEXT;
    v_msg_content TEXT;
    v_enc_content TEXT;
BEGIN
    -- Buscar flow
    SELECT id, tenant_id INTO v_flow_id, v_tenant_id
    FROM flows
    WHERE assistente_id::text = v_assistente_id::text
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_flow_id IS NULL THEN
        RAISE NOTICE '❌ Flow não encontrado';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Flow encontrado: %', v_flow_id;
    
    -- Buscar prompt_voz
    SELECT prompt_voz INTO v_prompt_voz
    FROM assistentes
    WHERE id = v_assistente_id;
    
    IF v_flow_id IS NULL OR v_prompt_voz IS NULL THEN
        RAISE NOTICE '❌ prompt_voz não encontrado';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ prompt_voz encontrado, length: %', LENGTH(v_prompt_voz);
    
    -- Deletar blocos existentes
    DELETE FROM flow_blocks WHERE flow_id = v_flow_id;
    DELETE FROM flow_routes WHERE flow_id = v_flow_id;
    RAISE NOTICE '✅ Blocos antigos deletados';
    
    -- Extrair conteúdo dos blocos do prompt_voz usando regex
    -- PM001 - Primeira Mensagem
    SELECT substring(v_prompt_voz from 'ABERTURA[^"]*"([^"]+)"') INTO v_pm_content;
    IF v_pm_content IS NULL OR v_pm_content = '' THEN
        v_pm_content := 'Olá! Aqui é a [Nome da IA]. Estou falando com [Nome do Lead]?';
    END IF;
    
    -- AG001 - Aguardar
    v_ag_content := 'Escute a confirmação do lead.';
    
    -- MSG001 - Mensagem
    SELECT substring(v_prompt_voz from 'MENSAGEM.*MSG001[^"]*"([^"]+)"') INTO v_msg_content;
    IF v_msg_content IS NULL OR v_msg_content = '' THEN
        v_msg_content := 'Perfeito! Em que posso ajudar?';
    END IF;
    
    -- ENC001 - Encerrar
    SELECT substring(v_prompt_voz from 'ENCERRAR.*ENC001[^"]*"([^"]+)"') INTO v_enc_content;
    IF v_enc_content IS NULL OR v_enc_content = '' THEN
        v_enc_content := 'Desculpe pelo engano. Até logo!';
    END IF;
    
    -- Inserir blocos
    INSERT INTO flow_blocks (
        flow_id, assistente_id, tenant_id, block_key, block_type, content,
        next_block_key, variable_name, order_index, position_x, position_y, tool_config, end_metadata
    ) VALUES
    -- PM001
    (v_flow_id, v_assistente_id, v_tenant_id, 'PM001', 'primeira_mensagem', v_pm_content, 'AG001', NULL, 1, 100, 150, '{}', '{}'),
    -- AG001
    (v_flow_id, v_assistente_id, v_tenant_id, 'AG001', 'aguardar', v_ag_content, 'CAM001', 'confirmacao_nome', 2, 100, 300, '{}', '{}'),
    -- CAM001
    (v_flow_id, v_assistente_id, v_tenant_id, 'CAM001', 'caminhos', 'É a pessoa certa?', NULL, NULL, 3, 100, 450, '{}', '{}'),
    -- MSG001
    (v_flow_id, v_assistente_id, v_tenant_id, 'MSG001', 'mensagem', v_msg_content, NULL, NULL, 4, 100, 600, '{}', '{}'),
    -- ENC001
    (v_flow_id, v_assistente_id, v_tenant_id, 'ENC001', 'encerrar', v_enc_content, NULL, NULL, 5, 100, 750, '{}', '{}');
    
    RAISE NOTICE '✅ 5 blocos inseridos com sucesso!';
END $$;

-- 3. REABILITAR TRIGGER (opcional - deixe desabilitado se continuar dando timeout)
-- ALTER TABLE flow_blocks ENABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 4. Verificar resultado
SELECT 
    block_key,
    block_type,
    LEFT(content, 60) as content_preview,
    next_block_key,
    order_index
FROM flow_blocks
WHERE flow_id = (
    SELECT id FROM flows 
    WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
    ORDER BY created_at DESC LIMIT 1
)
ORDER BY order_index;
