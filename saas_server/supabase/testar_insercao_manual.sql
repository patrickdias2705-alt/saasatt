-- ============================================================================
-- TESTE DE INSERÇÃO MANUAL
-- ============================================================================
-- Execute este script para testar se a inserção manual funciona
-- Substitua o flow_id abaixo pelo ID do seu flow

-- 1. Verificar se o flow existe
SELECT 
    '🔍 Flow encontrado?' as teste,
    id as flow_id,
    assistente_id,
    tenant_id,
    name
FROM flows
WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
ORDER BY created_at DESC
LIMIT 1;

-- 2. Tentar inserir um bloco de teste manualmente
-- ⚠️ SUBSTITUA O FLOW_ID ABAIXO PELO ID DO SEU FLOW
DO $$
DECLARE
    v_flow_id UUID;
    v_assistente_id TEXT;
    v_tenant_id TEXT;
    v_test_block_id UUID;
BEGIN
    -- Buscar flow_id
    SELECT id, assistente_id, tenant_id INTO v_flow_id, v_assistente_id, v_tenant_id
    FROM flows
    WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF v_flow_id IS NULL THEN
        RAISE NOTICE '❌ Flow não encontrado!';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Flow encontrado: %', v_flow_id;
    RAISE NOTICE '   assistente_id: %', v_assistente_id;
    RAISE NOTICE '   tenant_id: %', v_tenant_id;
    
    -- Tentar inserir um bloco de teste
    BEGIN
        INSERT INTO flow_blocks (
            flow_id,
            assistente_id,
            tenant_id,
            block_key,
            block_type,
            content,
            order_index,
            position_x,
            position_y
        ) VALUES (
            v_flow_id,
            v_assistente_id,
            v_tenant_id,
            'TEST001',
            'mensagem',
            'Este é um bloco de teste',
            999,
            0,
            0
        ) RETURNING id INTO v_test_block_id;
        
        RAISE NOTICE '✅ Bloco de teste inserido com sucesso! ID: %', v_test_block_id;
        
        -- Deletar o bloco de teste
        DELETE FROM flow_blocks WHERE id = v_test_block_id;
        RAISE NOTICE '✅ Bloco de teste deletado';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erro ao inserir bloco de teste: %', SQLERRM;
        RAISE NOTICE '   Código do erro: %', SQLSTATE;
    END;
END $$;

-- 3. Verificar status do trigger
SELECT 
    '🔍 Status do Trigger' as teste,
    tgname,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
        WHEN tgenabled = 'O' THEN '⚠️ ATIVO (pode causar timeout!)'
        ELSE 'Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';
