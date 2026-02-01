-- Script para limpar blocos padrão (PM001, AG001, CAM001, MSG001, ENC001) de todos os flows
-- Execute este script no SQL Editor do Supabase se quiser remover blocos padrão de flows existentes

-- 1. Deletar rotas dos blocos padrão primeiro (devido à foreign key)
DELETE FROM flow_routes
WHERE block_id IN (
  SELECT id FROM flow_blocks
  WHERE block_key IN ('PM001', 'AG001', 'CAM001', 'MSG001', 'ENC001')
);

-- 2. Deletar os blocos padrão
DELETE FROM flow_blocks
WHERE block_key IN ('PM001', 'AG001', 'CAM001', 'MSG001', 'ENC001');

-- Verificar quantos blocos foram deletados
SELECT 
  'Blocos deletados' as tipo,
  COUNT(*) as total
FROM flow_blocks
WHERE block_key IN ('PM001', 'AG001', 'CAM001', 'MSG001', 'ENC001')
UNION ALL
SELECT 
  'Rotas deletadas' as tipo,
  COUNT(*) as total
FROM flow_routes
WHERE block_id IN (
  SELECT id FROM flow_blocks
  WHERE block_key IN ('PM001', 'AG001', 'CAM001', 'MSG001', 'ENC001')
);

-- Se quiser ver quais flows tinham blocos padrão antes de deletar, execute:
-- SELECT DISTINCT flow_id, block_key 
-- FROM flow_blocks 
-- WHERE block_key IN ('PM001', 'AG001', 'CAM001', 'MSG001', 'ENC001')
-- ORDER BY flow_id, block_key;
