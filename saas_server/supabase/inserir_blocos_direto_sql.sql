-- ============================================================================
-- INSERIR BLOCOS DIRETAMENTE VIA SQL (evita timeout do trigger)
-- ============================================================================
-- Este script insere blocos diretamente no banco, evitando o trigger que causa timeout
-- Execute este script no Supabase SQL Editor quando os blocos não estão sendo gerados

-- ⚠️ SUBSTITUA OS VALORES:
-- flow_id: '39acbe34-4b1c-458a-b4ef-1580801ada3a'
-- assistente_id: 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
-- tenant_id: '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc'

-- 1. Desabilitar trigger temporariamente
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 2. Deletar blocos existentes (se houver)
DELETE FROM flow_blocks 
WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a';

-- 3. Inserir blocos diretamente (baseado no prompt_voz do assistente)
-- Você precisa ajustar os valores baseado no prompt_voz do assistente

INSERT INTO flow_blocks (
    flow_id,
    assistente_id,
    tenant_id,
    block_key,
    block_type,
    content,
    next_block_key,
    variable_name,
    analyze_variable,
    order_index,
    position_x,
    position_y,
    tool_config,
    end_metadata
) VALUES
-- PM001 - Primeira Mensagem
(
    '39acbe34-4b1c-458a-b4ef-1580801ada3a',
    'e7dfde93-35d2-44ee-8c4b-589fd408d00b',
    '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc',
    'PM001',
    'primeira_mensagem',
    'Olá! Aqui é a [Nome da IA]. Estou falando com [Nome do Lead]?',
    'AG001',
    NULL,
    NULL,
    1,
    100,
    150,
    '{}',
    '{}'
),
-- AG001 - Aguardar
(
    '39acbe34-4b1c-458a-b4ef-1580801ada3a',
    'e7dfde93-35d2-44ee-8c4b-589fd408d00b',
    '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc',
    'AG001',
    'aguardar',
    'Escute a confirmação do lead.',
    'CAM001',
    'confirmacao_nome',
    NULL,
    2,
    100,
    300,
    '{}',
    '{}'
),
-- CAM001 - Caminhos
(
    '39acbe34-4b1c-458a-b4ef-1580801ada3a',
    'e7dfde93-35d2-44ee-8c4b-589fd408d00b',
    '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc',
    'CAM001',
    'caminhos',
    'É a pessoa certa?',
    NULL,
    NULL,
    'confirmacao_nome',
    3,
    100,
    450,
    '{}',
    '{}'
),
-- MSG001 - Mensagem
(
    '39acbe34-4b1c-458a-b4ef-1580801ada3a',
    'e7dfde93-35d2-44ee-8c4b-589fd408d00b',
    '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc',
    'MSG001',
    'mensagem',
    'Perfeito! Em que posso ajudar?',
    NULL,
    NULL,
    NULL,
    4,
    100,
    600,
    '{}',
    '{}'
),
-- ENC001 - Encerrar
(
    '39acbe34-4b1c-458a-b4ef-1580801ada3a',
    'e7dfde93-35d2-44ee-8c4b-589fd408d00b',
    '088a6cbd-4fc7-4010-8d96-8dbf2b9680bc',
    'ENC001',
    'encerrar',
    'Desculpe pelo engano. Até logo!',
    NULL,
    NULL,
    NULL,
    5,
    100,
    750,
    '{}',
    '{}'
);

-- 4. Reabilitar trigger
ALTER TABLE flow_blocks ENABLE TRIGGER trigger_sync_prompt_voz_on_block_change;

-- 5. Verificar se foram inseridos
SELECT 
    block_key,
    block_type,
    content,
    next_block_key,
    order_index
FROM flow_blocks
WHERE flow_id = '39acbe34-4b1c-458a-b4ef-1580801ada3a'
ORDER BY order_index;
