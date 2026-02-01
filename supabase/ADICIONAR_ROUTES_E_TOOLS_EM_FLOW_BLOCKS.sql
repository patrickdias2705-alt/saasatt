-- ============================================================================
-- ADICIONAR ROUTES E TOOLS EM flow_blocks
-- Adiciona campos JSONB para armazenar routes e melhorar tool_config
-- Isso permite ver e editar routes/tools diretamente no bloco
-- ============================================================================

-- 1. ADICIONAR CAMPO routes (JSONB) EM flow_blocks
ALTER TABLE flow_blocks
ADD COLUMN IF NOT EXISTS routes JSONB DEFAULT '[]'::jsonb;

-- 2. MELHORAR tool_config (já existe, mas vamos garantir estrutura)
-- tool_config já existe como JSONB, vamos apenas documentar a estrutura esperada:
-- {
--   "tool_id": "uuid",
--   "tool_name": "nome da tool",
--   "parameters": {...},
--   "enabled": true/false
-- }

-- 3. CRIAR FUNÇÃO PARA SINCRONIZAR routes DE flow_routes PARA flow_blocks.routes
CREATE OR REPLACE FUNCTION sync_routes_to_block()
RETURNS TRIGGER AS $$
DECLARE
    v_block_id UUID;
    v_routes_json JSONB;
BEGIN
    -- Determinar qual block_id atualizar
    IF TG_OP = 'DELETE' THEN
        v_block_id := OLD.block_id;
    ELSE
        v_block_id := NEW.block_id;
    END IF;
    
    -- Buscar todas as routes do bloco e converter para JSONB
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', id,
            'route_key', route_key,
            'label', label,
            'ordem', ordem,
            'cor', cor,
            'keywords', keywords,
            'response', response,
            'destination_type', destination_type,
            'destination_block_key', destination_block_key,
            'max_loop_attempts', max_loop_attempts,
            'is_fallback', is_fallback
        ) ORDER BY ordem
    ), '[]'::jsonb)
    INTO v_routes_json
    FROM flow_routes
    WHERE block_id = v_block_id;
    
    -- Atualizar o campo routes no flow_blocks
    UPDATE flow_blocks
    SET routes = v_routes_json
    WHERE id = v_block_id;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 4. CRIAR TRIGGER PARA SINCRONIZAR AUTOMATICAMENTE
DROP TRIGGER IF EXISTS trigger_sync_routes_to_block ON flow_routes;
CREATE TRIGGER trigger_sync_routes_to_block
    AFTER INSERT OR UPDATE OR DELETE ON flow_routes
    FOR EACH ROW
    EXECUTE FUNCTION sync_routes_to_block();

-- 5. POPULAR routes EM TODOS OS BLOCOS EXISTENTES
DO $$
DECLARE
    v_block RECORD;
    v_routes_json JSONB;
BEGIN
    FOR v_block IN SELECT id FROM flow_blocks WHERE block_type = 'caminhos' LOOP
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'id', id,
                'route_key', route_key,
                'label', label,
                'ordem', ordem,
                'cor', cor,
                'keywords', keywords,
                'response', response,
                'destination_type', destination_type,
                'destination_block_key', destination_block_key,
                'max_loop_attempts', max_loop_attempts,
                'is_fallback', is_fallback
            ) ORDER BY ordem
        ), '[]'::jsonb)
        INTO v_routes_json
        FROM flow_routes
        WHERE block_id = v_block.id;
        
        UPDATE flow_blocks
        SET routes = v_routes_json
        WHERE id = v_block.id;
        
        RAISE NOTICE '✅ Bloco % atualizado com % routes', v_block.id, jsonb_array_length(v_routes_json);
    END LOOP;
END $$;

-- 6. CRIAR ÍNDICE GIN PARA BUSCAS RÁPIDAS EM routes
CREATE INDEX IF NOT EXISTS idx_flow_blocks_routes_gin ON flow_blocks USING GIN (routes);

-- 7. VERIFICAR RESULTADO
SELECT 
    '✅ VERIFICAÇÃO' as acao,
    block_key,
    block_type,
    CASE 
        WHEN block_type = 'caminhos' THEN 
            jsonb_array_length(routes)::text || ' routes'
        WHEN block_type = 'ferramenta' THEN 
            CASE 
                WHEN tool_config IS NOT NULL AND tool_config != '{}'::jsonb THEN 
                    'Tool configurada'
                ELSE 
                    'Sem tool'
            END
        ELSE 
            '-'
    END as detalhes,
    routes as routes_json,
    tool_config as tool_config_json
FROM flow_blocks
WHERE block_type IN ('caminhos', 'ferramenta')
ORDER BY block_key
LIMIT 10;

-- 8. COMENTÁRIOS SOBRE A ESTRUTURA
COMMENT ON COLUMN flow_blocks.routes IS 
'Array JSONB das routes deste bloco (apenas para blocos tipo "caminhos"). 
Sincronizado automaticamente com a tabela flow_routes via trigger.
Formato: [{"id": "uuid", "route_key": "...", "label": "...", "keywords": [...], ...}]';

COMMENT ON COLUMN flow_blocks.tool_config IS 
'Configuração da tool (apenas para blocos tipo "ferramenta").
Formato: {"tool_id": "uuid", "tool_name": "...", "parameters": {...}, "enabled": true}';
