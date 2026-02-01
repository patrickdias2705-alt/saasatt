-- ============================================================================
-- TESTE COMPLETO: Verificar se a sincronização está funcionando
-- ============================================================================
-- Execute este SQL para verificar se tudo está batendo entre flow_blocks e prompt_voz

-- ⚠️ SUBSTITUA O ASSISTENTE_ID ABAIXO:
\set assistente_id 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'

-- 1. VERIFICAR SE O TRIGGER ESTÁ ATIVO
SELECT 
    '🔍 TRIGGER' as teste,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Trigger está ativo'
        ELSE '❌ Trigger NÃO está ativo'
    END as status,
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'trigger_sync_prompt_voz_on_block_change'
GROUP BY trigger_name, event_manipulation, event_object_table;

-- 2. VERIFICAR CONTEÚDO DOS BLOCOS NO BANCO
SELECT 
    '📦 BLOCOS NO BANCO' as teste,
    block_key,
    block_type,
    LEFT(content, 80) as content_preview,
    flow_id
FROM flow_blocks
WHERE flow_id IN (
    SELECT id FROM flows WHERE assistente_id = :assistente_id
)
ORDER BY order_index;

-- 3. VERIFICAR CONTEÚDO NO PROMPT_VOZ DO ASSISTENTE
SELECT 
    '📝 PROMPT_VOZ DO ASSISTENTE' as teste,
    id as assistente_id,
    LENGTH(prompt_voz) as tamanho_prompt,
    -- Extrair seção ENC001 se existir
    CASE 
        WHEN position('### ENCERRAR [ENC001]' IN prompt_voz) > 0 THEN
            substring(
                prompt_voz,
                position('### ENCERRAR [ENC001]' IN prompt_voz),
                200
            )
        ELSE '❌ Seção ENC001 não encontrada'
    END as secao_enc001_no_prompt,
    -- Extrair seção MSG001 se existir
    CASE 
        WHEN position('### MENSAGEM [MSG001]' IN prompt_voz) > 0 THEN
            substring(
                prompt_voz,
                position('### MENSAGEM [MSG001]' IN prompt_voz),
                200
            )
        ELSE '❌ Seção MSG001 não encontrada'
    END as secao_msg001_no_prompt
FROM assistentes
WHERE id = :assistente_id;

-- 4. COMPARAR: Bloco ENC001 no banco vs Prompt_voz
SELECT 
    '🔍 COMPARAÇÃO ENC001' as teste,
    fb.content as conteudo_no_banco,
    CASE 
        WHEN position('### ENCERRAR [ENC001]' IN a.prompt_voz) > 0 THEN
            substring(
                a.prompt_voz,
                position('### ENCERRAR [ENC001]' IN a.prompt_voz),
                300
            )
        ELSE '❌ Não encontrado no prompt_voz'
    END as conteudo_no_prompt_voz,
    CASE 
        WHEN position('### ENCERRAR [ENC001]' IN a.prompt_voz) > 0 
             AND position(fb.content IN a.prompt_voz) > 0 THEN
            '✅ CONTEÚDO BATE'
        WHEN position('### ENCERRAR [ENC001]' IN a.prompt_voz) = 0 THEN
            '❌ Seção não encontrada no prompt_voz'
        ELSE
            '⚠️ CONTEÚDO NÃO BATE'
    END as status_sincronizacao
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
JOIN assistentes a ON a.id = f.assistente_id
WHERE fb.block_key = 'ENC001'
  AND f.assistente_id = :assistente_id
LIMIT 1;

-- 5. TESTE MANUAL: Modificar um bloco e verificar se o trigger atualiza
-- (Execute este passo manualmente: modifique um bloco no Flow Editor e salve,
--  depois execute novamente a query 4 para ver se atualizou)

-- 6. TESTAR FUNÇÃO DE PATCH MANUALMENTE
SELECT 
    '🧪 TESTE DA FUNÇÃO PATCH' as teste,
    CASE 
        WHEN patch_block_section_in_prompt(
            (SELECT prompt_voz FROM assistentes WHERE id = :assistente_id),
            'ENC001',
            'encerrar',
            '### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"TESTE DE SINCRONIZAÇÃO - Se você vê isso, a função funciona!"'
        ) IS NOT NULL THEN
            '✅ Função retorna resultado válido'
        ELSE
            '❌ Função retornou NULL'
    END as status_funcao;

-- 7. VERIFICAR TODOS OS BLOCOS E SUAS SEÇÕES NO PROMPT_VOZ
SELECT 
    '📊 RESUMO GERAL' as teste,
    COUNT(DISTINCT fb.block_key) as total_blocos_no_banco,
    COUNT(DISTINCT CASE 
        WHEN a.prompt_voz LIKE '%### ' || UPPER(REPLACE(fb.block_type, '_', ' ')) || ' [' || fb.block_key || ']%' 
        THEN fb.block_key 
    END) as blocos_encontrados_no_prompt_voz,
    COUNT(DISTINCT CASE 
        WHEN a.prompt_voz NOT LIKE '%### ' || UPPER(REPLACE(fb.block_type, '_', ' ')) || ' [' || fb.block_key || ']%' 
        THEN fb.block_key 
    END) as blocos_nao_encontrados
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
JOIN assistentes a ON a.id = f.assistente_id
WHERE f.assistente_id = :assistente_id;
