-- ============================================================================
-- VERIFICAR TRIGGER E TESTAR INSERÇÃO
-- ============================================================================

-- 1. Verificar status do trigger (CRÍTICO!)
SELECT 
    '🔍 STATUS DO TRIGGER' as verificacao,
    tgname as nome_trigger,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO (OK)'
        WHEN tgenabled = 'O' THEN '❌ ATIVO (CAUSA TIMEOUT!)'
        ELSE 'Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- 2. Se estiver ATIVO, desabilitar:
-- ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 3. Verificar constraints da tabela flow_blocks
SELECT 
    '🔍 CONSTRAINTS' as verificacao,
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'flow_blocks'::regclass
ORDER BY contype;

-- 4. Verificar se há blocos duplicados (pode causar erro UNIQUE)
SELECT 
    '🔍 DUPLICATAS' as verificacao,
    flow_id,
    block_key,
    COUNT(*) as quantidade
FROM flow_blocks
GROUP BY flow_id, block_key
HAVING COUNT(*) > 1;

-- 5. Verificar tipos de dados esperados
SELECT 
    '🔍 ESTRUTURA DA TABELA' as verificacao,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'flow_blocks'
ORDER BY ordinal_position;
