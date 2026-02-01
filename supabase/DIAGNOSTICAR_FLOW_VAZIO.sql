-- Diagnosticar por que um flow não está carregando blocos
-- Substitua o assistente_id abaixo pelo ID do assistente que está com problema

-- 1. Verificar se o flow existe
SELECT 
    id,
    assistente_id,
    tenant_id,
    name,
    LENGTH(prompt_base) as prompt_base_length,
    version,
    created_at
FROM flows
WHERE assistente_id = 'be63d2a6-2091-40f6-bc77-1206cc6fd091'  -- SUBSTITUA PELO ID DO ASSISTENTE
ORDER BY created_at DESC
LIMIT 5;

-- 2. Verificar se há blocos para este flow
SELECT 
    fb.id,
    fb.block_key,
    fb.block_type,
    fb.content,
    fb.order_index,
    COUNT(fr.id) as routes_count
FROM flow_blocks fb
LEFT JOIN flow_routes fr ON fr.block_id = fb.id
WHERE fb.flow_id = (
    SELECT id FROM flows 
    WHERE assistente_id = 'be63d2a6-2091-40f6-bc77-1206cc6fd091'  -- SUBSTITUA PELO ID DO ASSISTENTE
    ORDER BY created_at DESC
    LIMIT 1
)
GROUP BY fb.id, fb.block_key, fb.block_type, fb.content, fb.order_index
ORDER BY fb.order_index;

-- 3. Verificar se o prompt_voz do assistente existe
SELECT 
    id,
    LENGTH(prompt_voz) as prompt_voz_length,
    SUBSTRING(prompt_voz, 1, 200) as prompt_voz_preview
FROM assistentes  -- Tente também: assistents, assistants
WHERE id = 'be63d2a6-2091-40f6-bc77-1206cc6fd091'  -- SUBSTITUA PELO ID DO ASSISTENTE
LIMIT 1;

-- 4. Verificar se há múltiplos flows para o mesmo assistente
SELECT 
    id,
    assistente_id,
    LENGTH(prompt_base) as prompt_base_length,
    version,
    created_at
FROM flows
WHERE assistente_id = 'be63d2a6-2091-40f6-bc77-1206cc6fd091'  -- SUBSTITUA PELO ID DO ASSISTENTE
ORDER BY created_at DESC;

-- 5. Verificar se há blocos em flows antigos (pode estar usando flow errado)
SELECT 
    f.id as flow_id,
    f.assistente_id,
    COUNT(fb.id) as blocks_count,
    COUNT(fr.id) as routes_count
FROM flows f
LEFT JOIN flow_blocks fb ON fb.flow_id = f.id
LEFT JOIN flow_routes fr ON fr.flow_id = f.id
WHERE f.assistente_id = 'be63d2a6-2091-40f6-bc77-1206cc6fd091'  -- SUBSTITUA PELO ID DO ASSISTENTE
GROUP BY f.id, f.assistente_id
ORDER BY f.created_at DESC;
