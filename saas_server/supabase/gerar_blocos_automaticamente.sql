-- ============================================================================
-- GERAR BLOCOS AUTOMATICAMENTE DO PROMPT_VOZ DO ASSISTENTE
-- ============================================================================
-- Este script busca o prompt_voz do assistente, gera blocos automaticamente
-- e insere diretamente no banco, evitando timeout do trigger

-- ⚠️ SUBSTITUA O ASSISTENTE_ID:
DO $$
DECLARE
    v_assistente_id UUID := 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';
    v_flow_id UUID;
    v_tenant_id UUID;
    v_prompt_voz TEXT;
BEGIN
    -- 1. Buscar flow_id e tenant_id
    SELECT id, tenant_id INTO v_flow_id, v_tenant_id
    FROM flows
    WHERE assistente_id::text = v_assistente_id::text
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_flow_id IS NULL THEN
        RAISE NOTICE '❌ Flow não encontrado para assistente %', v_assistente_id;
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Flow encontrado: %', v_flow_id;
    
    -- 2. Buscar prompt_voz do assistente
    SELECT prompt_voz INTO v_prompt_voz
    FROM assistentes
    WHERE id = v_assistente_id;
    
    IF v_prompt_voz IS NULL OR v_prompt_voz = '' THEN
        RAISE NOTICE '❌ prompt_voz não encontrado para assistente %', v_assistente_id;
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ prompt_voz encontrado, length: %', LENGTH(v_prompt_voz);
    
    -- 3. Desabilitar trigger temporariamente
    ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
    RAISE NOTICE '✅ Trigger desabilitado temporariamente';
    
    -- 4. Deletar blocos existentes
    DELETE FROM flow_blocks WHERE flow_id = v_flow_id;
    DELETE FROM flow_routes WHERE flow_id = v_flow_id;
    RAISE NOTICE '✅ Blocos e rotas antigos deletados';
    
    -- 5. Inserir blocos baseados no prompt_voz
    -- (Você precisa ajustar os valores baseado no conteúdo real do prompt_voz)
    
    -- PM001 - Primeira Mensagem (se existir no prompt)
    IF v_prompt_voz ~* 'PM001|ABERTURA' THEN
        INSERT INTO flow_blocks (
            flow_id, assistente_id, tenant_id, block_key, block_type, content, 
            next_block_key, order_index, position_x, position_y, tool_config, end_metadata
        ) VALUES (
            v_flow_id, v_assistente_id, v_tenant_id, 'PM001', 'primeira_mensagem',
            COALESCE(
                (SELECT substring(v_prompt_voz from 'ABERTURA[^"]*"([^"]+)"' limit 1)),
                'Olá! Aqui é a [Nome da IA]. Estou falando com [Nome do Lead]?'
            ),
            'AG001', 1, 100, 150, '{}', '{}'
        );
        RAISE NOTICE '✅ PM001 inserido';
    END IF;
    
    -- AG001 - Aguardar (se existir no prompt)
    IF v_prompt_voz ~* 'AG001|AGUARDAR.*AG001' THEN
        INSERT INTO flow_blocks (
            flow_id, assistente_id, tenant_id, block_key, block_type, content,
            next_block_key, variable_name, order_index, position_x, position_y, tool_config, end_metadata
        ) VALUES (
            v_flow_id, v_assistente_id, v_tenant_id, 'AG001', 'aguardar',
            'Escute a confirmação do lead.',
            'CAM001', 'confirmacao_nome', 2, 100, 300, '{}', '{}'
        );
        RAISE NOTICE '✅ AG001 inserido';
    END IF;
    
    -- CAM001 - Caminhos (se existir no prompt)
    IF v_prompt_voz ~* 'CAM001|CAMINHOS.*CAM001' THEN
        INSERT INTO flow_blocks (
            flow_id, assistente_id, tenant_id, block_key, block_type, content,
            analyze_variable, order_index, position_x, position_y, tool_config, end_metadata
        ) VALUES (
            v_flow_id, v_assistente_id, v_tenant_id, 'CAM001', 'caminhos',
            'É a pessoa certa?',
            'confirmacao_nome', 3, 100, 450, '{}', '{}'
        );
        RAISE NOTICE '✅ CAM001 inserido';
    END IF;
    
    -- MSG001 - Mensagem (se existir no prompt)
    IF v_prompt_voz ~* 'MSG001|MENSAGEM.*MSG001' THEN
        INSERT INTO flow_blocks (
            flow_id, assistente_id, tenant_id, block_key, block_type, content,
            order_index, position_x, position_y, tool_config, end_metadata
        ) VALUES (
            v_flow_id, v_assistente_id, v_tenant_id, 'MSG001', 'mensagem',
            COALESCE(
                (SELECT substring(v_prompt_voz from 'MENSAGEM.*MSG001[^"]*"([^"]+)"' limit 1)),
                'Perfeito! Em que posso ajudar?'
            ),
            4, 100, 600, '{}', '{}'
        );
        RAISE NOTICE '✅ MSG001 inserido';
    END IF;
    
    -- ENC001 - Encerrar (se existir no prompt)
    IF v_prompt_voz ~* 'ENC001|ENCERRAR.*ENC001' THEN
        INSERT INTO flow_blocks (
            flow_id, assistente_id, tenant_id, block_key, block_type, content,
            order_index, position_x, position_y, tool_config, end_metadata
        ) VALUES (
            v_flow_id, v_assistente_id, v_tenant_id, 'ENC001', 'encerrar',
            COALESCE(
                (SELECT substring(v_prompt_voz from 'ENCERRAR.*ENC001[^"]*"([^"]+)"' limit 1)),
                'Desculpe pelo engano. Até logo!'
            ),
            5, 100, 750, '{}', '{}'
        );
        RAISE NOTICE '✅ ENC001 inserido';
    END IF;
    
    -- 6. Reabilitar trigger
    ALTER TABLE flow_blocks ENABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
    RAISE NOTICE '✅ Trigger reabilitado';
    
    -- 7. Mostrar resultado
    RAISE NOTICE '✅ Concluído! Blocos inseridos:';
    FOR rec IN 
        SELECT block_key, block_type, LEFT(content, 50) as content_preview
        FROM flow_blocks
        WHERE flow_id = v_flow_id
        ORDER BY order_index
    LOOP
        RAISE NOTICE '  - % (%): %', rec.block_key, rec.block_type, rec.content_preview;
    END LOOP;
END $$;

-- Verificar resultado
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
