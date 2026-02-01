-- ============================================================================
-- VERIFICAR E CRIAR FUNÇÃO RPC update_flow_block_simple
-- ============================================================================

-- 1. Verificar se a função já existe
SELECT 
  '🔍 VERIFICANDO FUNÇÃO' as acao,
  proname as nome_funcao,
  pg_get_function_arguments(oid) as argumentos,
  pg_get_function_result(oid) as retorno
FROM pg_proc 
WHERE proname = 'update_flow_block_simple';

-- 2. Se não existir, criar a função
-- (Execute apenas se a função não existir acima)

CREATE OR REPLACE FUNCTION update_flow_block_simple(
  p_flow_id UUID,
  p_block_key TEXT,
  p_block_type TEXT,
  p_content TEXT,
  p_order_index INTEGER DEFAULT 0,
  p_position_x FLOAT DEFAULT 0,
  p_position_y FLOAT DEFAULT 0,
  p_variable_name TEXT DEFAULT NULL,
  p_timeout_seconds INTEGER DEFAULT NULL,
  p_analyze_variable TEXT DEFAULT NULL,
  p_tool_type TEXT DEFAULT NULL,
  p_tool_config JSONB DEFAULT '{}'::jsonb,
  p_end_type TEXT DEFAULT NULL,
  p_end_metadata JSONB DEFAULT '{}'::jsonb,
  p_next_block_key TEXT DEFAULT NULL
)
RETURNS TABLE(
  success BOOLEAN,
  action TEXT,
  block_id UUID
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_block_id UUID;
  v_action TEXT;
BEGIN
  -- Verificar se existe
  SELECT id INTO v_block_id
  FROM flow_blocks
  WHERE flow_id = p_flow_id AND block_key = p_block_key
  LIMIT 1;
  
  IF v_block_id IS NOT NULL THEN
    -- UPDATE
    UPDATE flow_blocks
    SET 
      block_type = p_block_type,
      content = p_content,
      order_index = p_order_index,
      position_x = p_position_x,
      position_y = p_position_y,
      variable_name = p_variable_name,
      timeout_seconds = p_timeout_seconds,
      analyze_variable = p_analyze_variable,
      tool_type = p_tool_type,
      tool_config = p_tool_config,
      end_type = p_end_type,
      end_metadata = p_end_metadata,
      next_block_key = p_next_block_key,
      updated_at = NOW()
    WHERE id = v_block_id;
    
    v_action := 'updated';
  ELSE
    -- INSERT
    INSERT INTO flow_blocks (
      flow_id, block_key, block_type, content, order_index,
      position_x, position_y, variable_name, timeout_seconds,
      analyze_variable, tool_type, tool_config, end_type,
      end_metadata, next_block_key
    )
    VALUES (
      p_flow_id, p_block_key, p_block_type, p_content, p_order_index,
      p_position_x, p_position_y, p_variable_name, p_timeout_seconds,
      p_analyze_variable, p_tool_type, p_tool_config, p_end_type,
      p_end_metadata, p_next_block_key
    )
    RETURNING id INTO v_block_id;
    
    v_action := 'inserted';
  END IF;
  
  RETURN QUERY SELECT TRUE, v_action, v_block_id;
END;
$$;

-- 3. Verificar novamente após criação
SELECT 
  '✅ FUNÇÃO CRIADA' as acao,
  proname as nome_funcao,
  pg_get_function_arguments(oid) as argumentos
FROM pg_proc 
WHERE proname = 'update_flow_block_simple';

-- 4. Testar a função (opcional - descomente para testar)
-- SELECT * FROM update_flow_block_simple(
--   '39acbe34-4b1c-458a-b4ef-1580801ada3a'::UUID,
--   'PM001',
--   'primeira_mensagem',
--   'Olá! Teste de atualização rápida',
--   1,
--   100,
--   150
-- );
