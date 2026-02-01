-- ============================================================================
-- DIAGNÓSTICO: Por que os blocos não foram inseridos?
-- ============================================================================

-- 1. Verificar se o flow existe
SELECT 
    '🔍 Flow encontrado?' as verificacao,
    id as flow_id,
    assistente_id,
    tenant_id,
    name,
    created_at
FROM flows
WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
ORDER BY created_at DESC
LIMIT 1;

-- 2. Verificar se o prompt_voz existe
SELECT 
    '🔍 prompt_voz encontrado?' as verificacao,
    id,
    LENGTH(prompt_voz) as prompt_length,
    LEFT(prompt_voz, 200) as prompt_preview
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';

-- 3. Verificar se há blocos no flow
SELECT 
    '🔍 Blocos existentes?' as verificacao,
    COUNT(*) as total_blocos,
    STRING_AGG(block_key, ', ') as block_keys
FROM flow_blocks
WHERE flow_id = (
    SELECT id FROM flows 
    WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
    ORDER BY created_at DESC LIMIT 1
);

-- 4. Verificar status do trigger
SELECT 
    '🔍 Status do trigger?' as verificacao,
    tgname as nome_trigger,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
        WHEN tgenabled = 'O' THEN '⚠️ ATIVO (pode causar timeout)'
        ELSE 'Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';

-- 5. Testar extração de conteúdo do prompt_voz
SELECT 
    '🔍 Teste de extração' as verificacao,
    substring(
        (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'),
        position('ABERTURA' IN (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b')),
        200
    ) as secao_abertura,
    substring(
        (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'),
        position('ENC001' IN (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b')),
        200
    ) as secao_enc001;
