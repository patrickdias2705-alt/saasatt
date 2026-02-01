-- ============================================================================
-- DIAGNÓSTICO COMPLETO: Por que está dando timeout?
-- ============================================================================

-- 1. Verificar TODOS os triggers na tabela flow_blocks
SELECT 
  '🔍 TRIGGERS' as tipo,
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
    WHEN tgenabled = 'O' THEN '❌ ATIVO'
    ELSE 'Status: ' || tgenabled
  END as status
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass
ORDER BY tgname;

-- 2. Verificar índices (índices faltando podem causar lentidão)
SELECT 
  '📊 ÍNDICES' as tipo,
  indexname as nome_indice,
  indexdef as definicao
FROM pg_indexes
WHERE tablename = 'flow_blocks'
ORDER BY indexname;

-- 3. Verificar constraints (constraints complexas podem causar lentidão)
SELECT 
  '🔒 CONSTRAINTS' as tipo,
  conname as constraint_name,
  contype as tipo,
  pg_get_constraintdef(oid) as definicao
FROM pg_constraint
WHERE conrelid = 'flow_blocks'::regclass
ORDER BY conname;

-- 4. Verificar quantos blocos existem (muitos dados podem causar lentidão)
SELECT 
  '📈 ESTATÍSTICAS' as tipo,
  COUNT(*) as total_blocos,
  COUNT(DISTINCT flow_id) as total_flows,
  COUNT(DISTINCT assistente_id) as total_assistentes
FROM flow_blocks;

-- 5. Verificar se há locks na tabela (outras operações podem estar bloqueando)
SELECT 
  '🔐 LOCKS' as tipo,
  locktype,
  mode,
  relation::regclass as tabela
FROM pg_locks
WHERE relation = 'flow_blocks'::regclass::oid;
