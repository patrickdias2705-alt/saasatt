-- DIAGNOSTICO SIMPLES - Execute cada query separadamente

-- Query 1: Verificar flow
SELECT id as flow_id, assistente_id, tenant_id, name
FROM flows
WHERE assistente_id::text = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
ORDER BY created_at DESC
LIMIT 1;

-- Query 2: Verificar prompt_voz
SELECT id, LENGTH(prompt_voz) as prompt_length, LEFT(prompt_voz, 200) as preview
FROM assistentes
WHERE id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b';

-- Query 3: Verificar blocos existentes
SELECT COUNT(*) as total_blocos, STRING_AGG(block_key, ', ') as block_keys
FROM flow_blocks
WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a';

-- Query 4: Verificar trigger
SELECT tgname, 
    CASE WHEN tgenabled = 'D' THEN 'DESABILITADO' 
         WHEN tgenabled = 'O' THEN 'ATIVO' 
         ELSE 'DESCONHECIDO' END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';
