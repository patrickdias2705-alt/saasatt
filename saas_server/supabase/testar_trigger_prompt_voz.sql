-- ============================================================================
-- TESTE: Verificar se o trigger está funcionando
-- ============================================================================

-- 1. Ver o conteúdo atual do prompt_voz
SELECT 
    id,
    LEFT(prompt_voz, 500) as prompt_preview,
    LENGTH(prompt_voz) as tamanho
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';  -- ⚠️ SUBSTITUA PELO SEU ASSISTENTE_ID

-- 2. Ver o conteúdo atual do bloco ENC001
SELECT 
    block_key,
    block_type,
    content,
    flow_id
FROM flow_blocks
WHERE block_key = 'ENC001'
ORDER BY created_at DESC
LIMIT 1;

-- 3. Verificar se o trigger existe
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'trigger_sync_prompt_voz_on_block_change';

-- 4. Ver o conteúdo exato do ENC001 no prompt_voz atual
SELECT 
    'Seção ENC001 no prompt_voz:' as tipo,
    substring(
        prompt_voz,
        position('### ENCERRAR [ENC001]' IN prompt_voz),
        CASE 
            WHEN position(E'\n###' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 50)) > 0 
            THEN position(E'\n###' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 50)) + 50
            WHEN position(E'\n---' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 50)) > 0
            THEN position(E'\n---' IN substring(prompt_voz FROM position('### ENCERRAR [ENC001]' IN prompt_voz) + 50)) + 50
            ELSE 200
        END
    ) as secao_enc001
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
AND position('### ENCERRAR [ENC001]' IN prompt_voz) > 0;

-- 5. Testar manualmente a função de patch
-- (Substitua os valores pelos seus)
SELECT 
    'Teste da função patch:' as tipo,
    patch_block_section_in_prompt(
        (SELECT prompt_voz FROM assistentes WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'),
        'ENC001',
        'encerrar',
        '### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logooooo!"'
    ) as resultado_teste;

-- 6. Verificar se o trigger está sendo disparado
-- Modifique um bloco e veja os logs no Supabase (Logs > Postgres Logs)
