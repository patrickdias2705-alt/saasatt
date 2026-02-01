-- ============================================================================
-- RESTAURAR BLOCOS PADRÃO PARA UM FLOW
-- Execute este SQL substituindo 'SEU_FLOW_ID' e 'SEU_ASSISTENTE_ID' pelos valores reais
-- ============================================================================

-- ⚠️ SUBSTITUA OS VALORES:
-- 'SEU_FLOW_ID' = ID do flow (UUID)
-- 'SEU_ASSISTENTE_ID' = ID do assistente
-- 'SEU_TENANT_ID' = ID do tenant

-- 1. VER O FLOW PRIMEIRO (para pegar os IDs corretos)
SELECT 
  id as flow_id,
  assistente_id,
  tenant_id,
  name as flow_name
FROM flows
WHERE assistente_id = 'SEU_ASSISTENTE_ID'  -- ⚠️ SUBSTITUA AQUI
ORDER BY created_at DESC
LIMIT 1;

-- 2. DELETAR BLOCOS E ROTAS EXISTENTES (se houver)
DELETE FROM flow_routes
WHERE flow_id = 'SEU_FLOW_ID';  -- ⚠️ SUBSTITUA PELO ID DO FLOW

DELETE FROM flow_blocks
WHERE flow_id = 'SEU_FLOW_ID';  -- ⚠️ SUBSTITUA PELO ID DO FLOW

-- 3. INSERIR BLOCOS PADRÃO
INSERT INTO flow_blocks (
  flow_id,
  assistente_id,
  tenant_id,
  block_key,
  block_type,
  content,
  next_block_key,
  order_index,
  position_x,
  position_y,
  variable_name,
  analyze_variable
) VALUES
  -- PM001: Primeira Mensagem
  (
    'SEU_FLOW_ID',  -- ⚠️ SUBSTITUA
    'SEU_ASSISTENTE_ID',  -- ⚠️ SUBSTITUA
    'SEU_TENANT_ID',  -- ⚠️ SUBSTITUA
    'PM001',
    'primeira_mensagem',
    'Olá! Aqui é a [Nome da IA]. Estou falando com [Nome do Lead]?',
    'AG001',
    1,
    100,
    50,
    NULL,
    NULL
  ),
  -- AG001: Aguardar
  (
    'SEU_FLOW_ID',
    'SEU_ASSISTENTE_ID',
    'SEU_TENANT_ID',
    'AG001',
    'aguardar',
    'Escute a confirmação do lead.',
    'CAM001',
    2,
    100,
    150,
    'confirmacao_nome',
    NULL
  ),
  -- CAM001: Caminhos
  (
    'SEU_FLOW_ID',
    'SEU_ASSISTENTE_ID',
    'SEU_TENANT_ID',
    'CAM001',
    'caminhos',
    'É a pessoa certa?',
    NULL,
    3,
    100,
    250,
    NULL,
    '{{confirmacao_nome}}'
  ),
  -- MSG001: Mensagem
  (
    'SEU_FLOW_ID',
    'SEU_ASSISTENTE_ID',
    'SEU_TENANT_ID',
    'MSG001',
    'mensagem',
    'Perfeito! Em que posso ajudar?',
    NULL,
    4,
    100,
    350,
    NULL,
    NULL
  ),
  -- ENC001: Encerrar
  (
    'SEU_FLOW_ID',
    'SEU_ASSISTENTE_ID',
    'SEU_TENANT_ID',
    'ENC001',
    'encerrar',
    'Desculpe pelo engano. Até logo!',
    NULL,
    5,
    100,
    450,
    NULL,
    NULL
  );

-- 4. BUSCAR O ID DO BLOCO CAM001 PARA INSERIR AS ROTAS
-- (Execute esta query primeiro para pegar o block_id)
SELECT id as cam001_block_id
FROM flow_blocks
WHERE flow_id = 'SEU_FLOW_ID'  -- ⚠️ SUBSTITUA
  AND block_key = 'CAM001';

-- 5. INSERIR ROTAS (substitua 'CAM001_BLOCK_ID' pelo ID retornado acima)
INSERT INTO flow_routes (
  flow_id,
  assistente_id,
  tenant_id,
  block_id,
  route_key,
  label,
  ordem,
  cor,
  keywords,
  response,
  destination_type,
  destination_block_key,
  max_loop_attempts,
  is_fallback
) VALUES
  -- Rota 1: Confirmou
  (
    'SEU_FLOW_ID',  -- ⚠️ SUBSTITUA
    'SEU_ASSISTENTE_ID',  -- ⚠️ SUBSTITUA
    'SEU_TENANT_ID',  -- ⚠️ SUBSTITUA
    'CAM001_BLOCK_ID',  -- ⚠️ SUBSTITUA PELO ID DO BLOCO CAM001
    'confirmou',
    'Confirmou que é ele',
    1,
    '#22c55e',
    ARRAY['sim', 'sou eu', 'isso', 'pode falar'],
    'Perfeito! Em que posso ajudar?',
    'continuar',
    'MSG001',
    2,
    false
  ),
  -- Rota 2: Não é a pessoa
  (
    'SEU_FLOW_ID',
    'SEU_ASSISTENTE_ID',
    'SEU_TENANT_ID',
    'CAM001_BLOCK_ID',  -- ⚠️ SUBSTITUA
    'nao_e_ele',
    'Não é a pessoa',
    2,
    '#ef4444',
    ARRAY['não', 'engano', 'número errado'],
    'Desculpe pelo engano. Até logo!',
    'encerrar',
    'ENC001',
    2,
    false
  ),
  -- Fallback
  (
    'SEU_FLOW_ID',
    'SEU_ASSISTENTE_ID',
    'SEU_TENANT_ID',
    'CAM001_BLOCK_ID',  -- ⚠️ SUBSTITUA
    'fallback',
    'Não entendi',
    999,
    '#6b7280',
    ARRAY[]::text[],
    'Não entendi. Estou falando com [Nome do Lead]?',
    'loop',
    'AG001',
    2,
    true
  );

-- 6. VERIFICAR SE FOI INSERIDO CORRETAMENTE
SELECT 
  '✅ VERIFICAÇÃO FINAL' as tipo,
  COUNT(*)::text as total_blocos,
  COUNT(DISTINCT block_type)::text as tipos_diferentes
FROM flow_blocks
WHERE flow_id = 'SEU_FLOW_ID';  -- ⚠️ SUBSTITUA

SELECT 
  '✅ VERIFICAÇÃO ROTAS' as tipo,
  COUNT(*)::text as total_rotas
FROM flow_routes
WHERE flow_id = 'SEU_FLOW_ID';  -- ⚠️ SUBSTITUA
