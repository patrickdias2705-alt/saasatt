-- ============================================================================
-- VERIFICAR TODOS OS TRIGGERS E FUNÇÕES QUE PODEM CAUSAR TIMEOUT
-- ============================================================================

-- 1. Verificar TODOS os triggers na tabela flow_blocks
SELECT 
  '🔍 TRIGGERS' as tipo,
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
    WHEN tgenabled = 'O' THEN '❌ ATIVO (PODE CAUSAR TIMEOUT!)'
    WHEN tgenabled = 'R' THEN '🔄 REVERT'
    WHEN tgenabled = 'A' THEN '✅ ALWAYS'
    ELSE 'Status: ' || tgenabled
  END as status,
  pg_get_triggerdef(oid) as definicao
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass
ORDER BY tgname;

-- 2. Verificar funções que podem estar sendo chamadas por triggers
SELECT 
  '⚙️ FUNÇÕES' as tipo,
  p.proname as function_name,
  pg_get_functiondef(p.oid) as definicao_preview
FROM pg_proc p
JOIN pg_trigger t ON t.tgfoid = p.oid
WHERE t.tgrelid = 'flow_blocks'::regclass;

-- 3. Verificar se há algum problema com foreign keys
SELECT 
  '🔗 FOREIGN KEYS' as tipo,
  conname as constraint_name,
  pg_get_constraintdef(oid) as definicao
FROM pg_constraint
WHERE conrelid = 'flow_blocks'::regclass
  AND contype = 'f';

-- 4. Verificar configuração de timeout do banco
SHOW statement_timeout;
