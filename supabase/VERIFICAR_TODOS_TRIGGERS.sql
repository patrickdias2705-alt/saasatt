-- ============================================================================
-- VERIFICAR TODOS OS TRIGGERS NA TABELA flow_blocks
-- ============================================================================

-- Listar todos os triggers na tabela flow_blocks
SELECT 
  tgname as trigger_name,
  CASE 
    WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
    WHEN tgenabled = 'O' THEN '❌ ATIVO'
    WHEN tgenabled = 'R' THEN '🔄 REVERT'
    WHEN tgenabled = 'A' THEN '✅ ALWAYS'
    ELSE 'Status: ' || tgenabled
  END as status,
  tgrelid::regclass as table_name
FROM pg_trigger 
WHERE tgrelid = 'flow_blocks'::regclass
ORDER BY tgname;

-- Verificar se há funções relacionadas que podem estar causando timeout
SELECT 
  proname as function_name,
  prosrc as function_source_preview
FROM pg_proc
WHERE proname LIKE '%prompt%' 
   OR proname LIKE '%sync%'
   OR proname LIKE '%block%'
ORDER BY proname;
