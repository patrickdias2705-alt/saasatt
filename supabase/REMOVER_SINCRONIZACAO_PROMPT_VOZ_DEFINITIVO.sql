-- ============================================================================
-- REMOVER COMPLETAMENTE SINCRONIZAÇÃO COM prompt_voz
-- Remove trigger e função que causam timeout
-- ============================================================================

-- 1. Desabilitar e remover TODOS os triggers relacionados a prompt_voz
ALTER TABLE flow_blocks DISABLE TRIGGER IF EXISTS trigger_sync_prompt_voz_on_block_change;
ALTER TABLE flow_blocks DISABLE TRIGGER IF EXISTS trigger_sync_prompt_voz_after_statement;

DROP TRIGGER IF EXISTS trigger_sync_prompt_voz_on_block_change ON flow_blocks;
DROP TRIGGER IF EXISTS trigger_sync_prompt_voz_after_statement ON flow_blocks;

-- 2. Remover TODAS as funções relacionadas a sincronização com prompt_voz
DROP FUNCTION IF EXISTS sync_prompt_voz_on_block_change() CASCADE;
DROP FUNCTION IF EXISTS sync_prompt_voz_on_block_change_with_ai_fallback() CASCADE;
DROP FUNCTION IF EXISTS sync_prompt_voz_after_statement() CASCADE;
DROP FUNCTION IF EXISTS patch_prompt_voz_with_block_content(TEXT, TEXT, TEXT, TEXT) CASCADE;

-- 3. Verificar que não há mais triggers ativos relacionados
SELECT 
  '🔍 VERIFICAÇÃO FINAL' as acao,
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
    WHEN tgenabled = 'O' THEN '❌ AINDA ATIVO!'
    ELSE 'Status: ' || tgenabled
  END as status
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass
  AND (tgname LIKE '%prompt_voz%' OR tgname LIKE '%sync%')
ORDER BY tgname;

-- 4. Recriar função update_flow_block_simple SIMPLES (sem sincronização)
-- Esta função busca assistente_id e tenant_id do flow automaticamente
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
  v_assistente_id TEXT;
  v_tenant_id TEXT;
BEGIN
  -- Buscar assistente_id e tenant_id do flow (uma vez só)
  SELECT assistente_id, tenant_id 
  INTO v_assistente_id, v_tenant_id
  FROM flows
  WHERE id = p_flow_id
  LIMIT 1;
  
  -- Verificar se existe bloco
  SELECT id INTO v_block_id
  FROM flow_blocks
  WHERE flow_id = p_flow_id AND block_key = p_block_key
  LIMIT 1;
  
  IF v_block_id IS NOT NULL THEN
    -- UPDATE simples e rápido (sem triggers pesados)
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
    -- INSERT simples e rápido (sem triggers pesados)
    -- Inclui assistente_id e tenant_id do flow
    INSERT INTO flow_blocks (
      flow_id, assistente_id, tenant_id, block_key, block_type, content, order_index,
      position_x, position_y, variable_name, timeout_seconds,
      analyze_variable, tool_type, tool_config, end_type,
      end_metadata, next_block_key
    )
    VALUES (
      p_flow_id, v_assistente_id, v_tenant_id, p_block_key, p_block_type, p_content, p_order_index,
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

-- 5. Verificar função criada
SELECT 
  '✅ FUNÇÃO CRIADA' as acao,
  proname as nome_funcao,
  pg_get_function_arguments(oid) as argumentos
FROM pg_proc 
WHERE proname = 'update_flow_block_simple';

-- 6. Verificar se há apenas o trigger de updated_at (esse é OK, é rápido)
SELECT 
  '📋 TRIGGERS RESTANTES' as acao,
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
    WHEN tgenabled = 'O' THEN '✅ ATIVO (OK se for updated_at)'
    ELSE 'Status: ' || tgenabled
  END as status
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass
ORDER BY tgname;
