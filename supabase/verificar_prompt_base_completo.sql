-- ============================================================================
-- VERIFICAR PROMPT_BASE COMPLETO DO FLOW
-- Para ver se tem blocos estruturados como [AG001], [CAM001], etc.
-- ============================================================================

SELECT 
  f.id::text as flow_id,
  f.assistente_id,
  f.tenant_id,
  f.prompt_base,  -- CONTEÚDO COMPLETO
  LENGTH(f.prompt_base) as prompt_length,
  -- Verificar se tem blocos estruturados
  CASE 
    WHEN f.prompt_base ~ '\[(PM|AG|CAM|MSG|ENC)\d+\]' THEN '✅ TEM BLOCOS ESTRUTURADOS'
    ELSE '❌ SEM BLOCOS ESTRUTURADOS'
  END as tem_blocos_estruturados,
  -- Mostrar quais blocos foram encontrados
  (
    SELECT array_agg(DISTINCT m[1] || m[2])
    FROM regexp_matches(f.prompt_base, '\[((PM|AG|CAM|MSG|ENC)(\d+))\]', 'g') m
  ) as blocos_encontrados
FROM flows f
WHERE f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'
ORDER BY f.created_at DESC
LIMIT 1;
