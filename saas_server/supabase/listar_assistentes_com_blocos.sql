-- ============================================================================
-- LISTAR TODOS OS ASSISTENTES E QUANTOS BLOCOS CADA UM TEM
-- Use este SQL para encontrar o assistente_id do "Copy - assistente de indicação - clinica"
-- ============================================================================

SELECT 
  f.id as flow_id,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  COUNT(DISTINCT fb.id) as total_blocos,
  COUNT(DISTINCT fr.id) as total_rotas,
  LEFT(f.prompt_base, 100) as prompt_preview,
  f.created_at
FROM flows f
LEFT JOIN flow_blocks fb ON fb.flow_id = f.id
LEFT JOIN flow_routes fr ON fr.flow_id = f.id
GROUP BY f.id, f.name, f.assistente_id, f.tenant_id, f.prompt_base, f.created_at
ORDER BY f.created_at DESC;

-- Para encontrar especificamente o "Copy - assistente de indicação - clinica":
SELECT 
  f.id as flow_id,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  COUNT(DISTINCT fb.id) as total_blocos,
  COUNT(DISTINCT fr.id) as total_rotas
FROM flows f
LEFT JOIN flow_blocks fb ON fb.flow_id = f.id
LEFT JOIN flow_routes fr ON fr.flow_id = f.id
WHERE f.name ILIKE '%Copy%' 
   OR f.name ILIKE '%indicacao%'
   OR f.name ILIKE '%clinica%'
   OR f.assistente_id ILIKE '%copy%'
GROUP BY f.id, f.name, f.assistente_id, f.tenant_id
ORDER BY f.created_at DESC;
