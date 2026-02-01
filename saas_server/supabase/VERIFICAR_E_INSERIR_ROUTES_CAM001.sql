-- ============================================================================
-- VERIFICAR E INSERIR ROUTES DO CAM001
-- Este script verifica se as routes do CAM001 estão no banco e as insere se necessário
-- ============================================================================

-- 1. Verificar se existe o bloco CAM001
SELECT 
    '🔍 VERIFICAÇÃO DO BLOCO CAM001' as acao,
    id as block_id,
    block_key,
    block_type,
    content,
    flow_id,
    assistente_id,
    tenant_id
FROM flow_blocks
WHERE block_key = 'CAM001'
ORDER BY created_at DESC
LIMIT 5;

-- 2. Verificar se existem routes para o CAM001
SELECT 
    '🔍 VERIFICAÇÃO DAS ROUTES DO CAM001' as acao,
    fr.id,
    fr.block_id,
    fr.route_key,
    fr.label,
    fr.keywords,
    fr.response,
    fr.destination_block_key,
    fr.destination_type,
    fr.is_fallback,
    fr.ordem,
    fb.block_key as block_key_do_bloco
FROM flow_routes fr
JOIN flow_blocks fb ON fb.id = fr.block_id
WHERE fb.block_key = 'CAM001'
ORDER BY fr.ordem;

-- 3. Se não existirem routes, inserir as routes padrão do CAM001
-- ⚠️ SUBSTITUA OS VALORES ABAIXO:
-- - v_flow_id: ID do flow
-- - v_assistente_id: ID do assistente
-- - v_tenant_id: ID do tenant

DO $$
DECLARE
    v_flow_id UUID := '39acbe34-4b1c-458a-b4ef-1580801ada3a';  -- ⚠️ SUBSTITUA
    v_assistente_id TEXT := 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';  -- ⚠️ SUBSTITUA
    v_tenant_id TEXT := '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc';  -- ⚠️ SUBSTITUA
    v_cam001_block_id UUID;
    v_routes_count INTEGER;
BEGIN
    -- Buscar o ID do bloco CAM001
    SELECT id INTO v_cam001_block_id
    FROM flow_blocks
    WHERE flow_id = v_flow_id
      AND block_key = 'CAM001'
    LIMIT 1;
    
    IF v_cam001_block_id IS NULL THEN
        RAISE NOTICE '❌ Bloco CAM001 não encontrado para o flow %', v_flow_id;
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Bloco CAM001 encontrado: %', v_cam001_block_id;
    
    -- Contar quantas routes já existem
    SELECT COUNT(*) INTO v_routes_count
    FROM flow_routes
    WHERE block_id = v_cam001_block_id;
    
    RAISE NOTICE '📊 Routes existentes: %', v_routes_count;
    
    -- Se não existirem routes, inserir as 3 routes padrão
    IF v_routes_count = 0 THEN
        RAISE NOTICE '➕ Inserindo routes do CAM001...';
        
        -- Route 1: Confirmou que é ele (+)
        INSERT INTO flow_routes (
            flow_id, block_id, assistente_id, tenant_id,
            route_key, label, ordem, cor, keywords, response,
            destination_type, destination_block_key, max_loop_attempts, is_fallback
        ) VALUES (
            v_flow_id, v_cam001_block_id, v_assistente_id, v_tenant_id,
            'CAM001_route_1', 'Confirmou que é ele', 1, '#22c55e',
            ARRAY['sim', 'sou eu', 'isso', 'pode falar']::TEXT[],
            'Perfeito! Em que posso ajudar?',
            'continuar', 'MSG001', 2, false
        );
        
        -- Route 2: Não é a pessoa (x)
        INSERT INTO flow_routes (
            flow_id, block_id, assistente_id, tenant_id,
            route_key, label, ordem, cor, keywords, response,
            destination_type, destination_block_key, max_loop_attempts, is_fallback
        ) VALUES (
            v_flow_id, v_cam001_block_id, v_assistente_id, v_tenant_id,
            'CAM001_route_2', 'Não é a pessoa', 2, '#ef4444',
            ARRAY['não', 'engano', 'número errado']::TEXT[],
            'Desculpe pelo engano. Até logo!',
            'encerrar', 'ENC001', 2, false
        );
        
        -- Route 3: Não entendi (?) - Fallback
        INSERT INTO flow_routes (
            flow_id, block_id, assistente_id, tenant_id,
            route_key, label, ordem, cor, keywords, response,
            destination_type, destination_block_key, max_loop_attempts, is_fallback
        ) VALUES (
            v_flow_id, v_cam001_block_id, v_assistente_id, v_tenant_id,
            'CAM001_fallback', 'Não entendi', 999, '#6b7280',
            ARRAY[]::TEXT[],
            'Não entendi. Estou falando com [Nome do Lead]?',
            'loop', 'AG001', 2, true
        );
        
        RAISE NOTICE '✅ 3 routes inseridas com sucesso!';
    ELSE
        RAISE NOTICE 'ℹ️ Routes já existem (% routes encontradas). Não foi necessário inserir.', v_routes_count;
    END IF;
END $$;

-- 4. Verificar resultado final
SELECT 
    '✅ RESULTADO FINAL' as acao,
    fr.id,
    fr.route_key,
    fr.label,
    fr.keywords,
    fr.response,
    fr.destination_block_key,
    fr.destination_type,
    fr.is_fallback,
    fr.ordem,
    fb.block_key
FROM flow_routes fr
JOIN flow_blocks fb ON fb.id = fr.block_id
WHERE fb.block_key = 'CAM001'
ORDER BY fr.ordem;
