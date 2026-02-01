-- Verificar blocos atuais no flow
SELECT 
    block_key,
    block_type,
    LEFT(content, 60) as content_preview,
    next_block_key,
    order_index,
    created_at,
    updated_at
FROM flow_blocks
WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a'
ORDER BY order_index;

-- Contar total
SELECT COUNT(*) as total_blocos FROM flow_blocks WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a';
