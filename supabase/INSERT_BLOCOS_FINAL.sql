DELETE FROM flow_routes WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a';

DELETE FROM flow_blocks WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a';

INSERT INTO flow_blocks (flow_id, assistente_id, tenant_id, block_key, block_type, content, next_block_key, variable_name, order_index, position_x, position_y, tool_config, end_metadata) VALUES ('39acbe34-4b1c-458a-b4ef-1580801ada3a', 'e7dfde93-35d2-44ee-8c4b-589fd408d00b', '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc', 'PM001', 'primeira_mensagem', 'Olá! Aqui é a [Nome da IA]. Estou falando com [Nome do Lead]?', 'AG001', NULL, 1, 100, 150, '{}', '{}');

INSERT INTO flow_blocks (flow_id, assistente_id, tenant_id, block_key, block_type, content, next_block_key, variable_name, order_index, position_x, position_y, tool_config, end_metadata) VALUES ('39acbe34-4b1c-458a-b4ef-1580801ada3a', 'e7dfde93-35d2-44ee-8c4b-589fd408d00b', '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc', 'AG001', 'aguardar', 'Escute a confirmação do lead.', 'CAM001', 'confirmacao_nome', 2, 100, 300, '{}', '{}');

INSERT INTO flow_blocks (flow_id, assistente_id, tenant_id, block_key, block_type, content, next_block_key, variable_name, order_index, position_x, position_y, tool_config, end_metadata) VALUES ('39acbe34-4b1c-458a-b4ef-1580801ada3a', 'e7dfde93-35d2-44ee-8c4b-589fd408d00b', '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc', 'CAM001', 'caminhos', 'É a pessoa certa?', NULL, NULL, 3, 100, 450, '{}', '{}');

INSERT INTO flow_blocks (flow_id, assistente_id, tenant_id, block_key, block_type, content, next_block_key, variable_name, order_index, position_x, position_y, tool_config, end_metadata) VALUES ('39acbe34-4b1c-458a-b4ef-1580801ada3a', 'e7dfde93-35d2-44ee-8c4b-589fd408d00b', '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc', 'MSG001', 'mensagem', 'Perfeito! Em que posso ajudar?', NULL, NULL, 4, 100, 600, '{}', '{}');

INSERT INTO flow_blocks (flow_id, assistente_id, tenant_id, block_key, block_type, content, next_block_key, variable_name, order_index, position_x, position_y, tool_config, end_metadata) VALUES ('39acbe34-4b1c-458a-b4ef-1580801ada3a', 'e7dfde93-35d2-44ee-8c4b-589fd408d00b', '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc', 'ENC001', 'encerrar', 'Desculpe pelo engano. Até logo!', NULL, NULL, 5, 100, 750, '{}', '{}');

SELECT block_key, block_type, LEFT(content, 50) as content, order_index FROM flow_blocks WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a' ORDER BY order_index;
