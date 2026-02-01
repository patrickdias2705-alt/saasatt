-- ============================================================================
-- VERIFICAR E CORRIGIR PROBLEMAS DE INSERÇÃO
-- ============================================================================
-- Execute este script NO SUPABASE SQL EDITOR

-- 1. DESABILITAR TRIGGER (OBRIGATÓRIO!)
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 2. Verificar status do trigger
SELECT 
    '🔍 STATUS DO TRIGGER' as verificacao,
    tgname as nome_trigger,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
        WHEN tgenabled = 'O' THEN '❌ AINDA ATIVO!'
        ELSE 'Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- 3. Verificar se há blocos duplicados (pode causar erro UNIQUE)
SELECT 
    '🔍 DUPLICATAS' as verificacao,
    flow_id,
    block_key,
    COUNT(*) as quantidade,
    STRING_AGG(id::text, ', ') as ids
FROM flow_blocks
GROUP BY flow_id, block_key
HAVING COUNT(*) > 1;

-- 4. Verificar constraints da tabela
SELECT 
    '🔍 CONSTRAINTS' as verificacao,
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'flow_blocks'::regclass
ORDER BY contype;

-- 5. Verificar estrutura da tabela (campos obrigatórios)
SELECT 
    '🔍 ESTRUTURA' as verificacao,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'flow_blocks'
ORDER BY ordinal_position;

-- 6. Se houver duplicatas, execute para limpar (SUBSTITUA O FLOW_ID):
-- DELETE FROM flow_blocks WHERE id IN (
--     SELECT id FROM (
--         SELECT id, ROW_NUMBER() OVER (PARTITION BY flow_id, block_key ORDER BY created_at DESC) as rn
--         FROM flow_blocks
--         WHERE flow_id = 'SUBSTITUA_PELO_FLOW_ID'
--     ) t WHERE rn > 1
-- );
