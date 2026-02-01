-- ============================================================================
-- VERIFICAR PROMPT DO ASSISTENTE PARA DEBUG
-- Substitua 'e7dfde93-35d2-44ee-8c4b-589fd408d00b' pelo assistente_id real
-- ============================================================================

-- 1. VER PROMPT_BASE DO FLOW
SELECT 
  '🔍 PROMPT_BASE DO FLOW' as tipo,
  f.id::text as flow_id,
  f.name as flow_name,
  f.assistente_id,
  f.tenant_id,
  f.prompt_base,
  LENGTH(f.prompt_base) as prompt_length,
  CASE 
    WHEN f.prompt_base ~ '\[(PM|AG|CAM|MSG|ENC)\d+\]' THEN '✅ TEM BLOCOS ESTRUTURADOS'
    ELSE '❌ SEM BLOCOS ESTRUTURADOS'
  END as tem_blocos_estruturados
FROM flows f
WHERE f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA PELO ID DO ASSISTENTE
ORDER BY f.created_at DESC
LIMIT 1;

-- 2. VER PROMPT_VOZ DO ASSISTENTE (tentar diferentes tabelas)
-- Tabela assistentes (CORRETO)
SELECT 
  '🔍 PROMPT_VOZ - assistentes' as tipo,
  assistente_id,
  prompt_voz,
  LENGTH(prompt_voz) as prompt_length,
  CASE 
    WHEN prompt_voz ~ '\[(PM|AG|CAM|MSG|ENC)\d+\]' THEN '✅ TEM BLOCOS ESTRUTURADOS'
    ELSE '❌ SEM BLOCOS ESTRUTURADOS'
  END as tem_blocos_estruturados
FROM assistentes
WHERE assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA PELO ID DO ASSISTENTE
LIMIT 1;

-- Tabela assistants (se existir)
SELECT 
  '🔍 PROMPT_VOZ - assistants' as tipo,
  assistente_id,
  prompt_voz,
  LENGTH(prompt_voz) as prompt_length,
  CASE 
    WHEN prompt_voz ~ '\[(PM|AG|CAM|MSG|ENC)\d+\]' THEN '✅ TEM BLOCOS ESTRUTURADOS'
    ELSE '❌ SEM BLOCOS ESTRUTURADOS'
  END as tem_blocos_estruturados
FROM assistants
WHERE assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- ⚠️ SUBSTITUA PELO ID DO ASSISTENTE
LIMIT 1;

-- 3. VER TODOS OS CAMPOS DA TABELA DE ASSISTENTES (para descobrir nome da tabela)
-- Listar todas as tabelas que podem conter assistentes
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (table_name LIKE '%assist%' OR table_name LIKE '%assistente%')
  AND (column_name LIKE '%prompt%' OR column_name LIKE '%assistente_id%')
ORDER BY table_name, column_name;
