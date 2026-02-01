-- ============================================================================
-- CRIAR ÍNDICE PARA MELHORAR PERFORMANCE DO UPDATE
-- Execute este SQL no Supabase
-- ============================================================================

-- Criar índice composto em (flow_id, block_key) - CRÍTICO para performance do UPDATE
CREATE INDEX IF NOT EXISTS idx_flow_blocks_flow_block_key 
ON flow_blocks(flow_id, block_key);

-- Verificar se foi criado
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'flow_blocks' 
  AND indexname = 'idx_flow_blocks_flow_block_key';

-- Verificar todos os índices na tabela
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'flow_blocks'
ORDER BY indexname;
