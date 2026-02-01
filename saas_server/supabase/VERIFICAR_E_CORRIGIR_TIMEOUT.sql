-- ============================================================================
-- VERIFICAR E CORRIGIR PROBLEMAS QUE CAUSAM TIMEOUT
-- ============================================================================

-- 1. Verificar TODOS os triggers (pode ter nome diferente)
SELECT 
  tgname as trigger_name,
  CASE WHEN tgenabled = 'D' THEN '✅ DESABILITADO' ELSE '❌ ATIVO' END as status
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass;

-- 2. Verificar se há índice em (flow_id, block_key) - CRÍTICO para performance
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'flow_blocks' 
  AND indexdef LIKE '%flow_id%'
  AND indexdef LIKE '%block_key%';

-- 3. Se não houver índice, criar um (isso vai acelerar muito o UPDATE)
CREATE INDEX IF NOT EXISTS idx_flow_blocks_flow_block_key 
ON flow_blocks(flow_id, block_key);

-- 4. Verificar quantos blocos existem (muitos dados podem causar lentidão)
SELECT COUNT(*) as total_blocos FROM flow_blocks;

-- 5. Verificar se há foreign keys que podem estar causando lentidão
SELECT 
  conname,
  pg_get_constraintdef(oid) as definicao
FROM pg_constraint
WHERE conrelid = 'flow_blocks'::regclass
  AND contype = 'f';
