-- Ver detalhes dos 5 blocos
SELECT 
    block_key,
    block_type,
    LEFT(content, 80) as content_preview,
    next_block_key,
    variable_name,
    order_index
FROM flow_blocks
WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a'
ORDER BY order_index;
