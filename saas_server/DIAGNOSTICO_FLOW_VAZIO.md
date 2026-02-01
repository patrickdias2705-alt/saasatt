# Diagnóstico: Flow não está carregando blocos

## 🔍 Problema Identificado

Pelos logs do frontend:
- Flow existe: `flowId: 'da0dd426-734d-4c52-890f-cf787b264465'`
- Mas `blocksCount: 0, routesCount: 0`
- `promptBaseLength: 0` (prompt_base está vazio)

## ✅ Correções Implementadas

1. **Logs melhorados** em `get_flow_complete()`:
   - Agora mostra quais padrões de blocos foram encontrados no prompt
   - Loga quando não encontra prompt_voz nem prompt_base
   - Loga quando o prompt não tem estrutura de blocos

2. **Logs melhorados** na API:
   - Mostra quando um flow não tem blocos
   - Mostra o tamanho do prompt_base

## 🔧 Como Diagnosticar

### Passo 1: Verificar logs do servidor

Procure por estas mensagens nos logs do servidor:

```
🌐 [API] get_flow_by_assistant: assistente_id=...
✅ [API] Flow encontrado: flow_id=..., prompt_base_length=...
get_flow_complete: Flow ... - prompt_to_parse length: X, has_block_structure: true/false
```

### Passo 2: Executar SQL de diagnóstico

Execute o arquivo `supabase/DIAGNOSTICAR_FLOW_VAZIO.sql` substituindo o `assistente_id`:

```sql
-- Substitua 'be63d2a6-2091-40f6-bc77-1206cc6fd091' pelo ID do assistente com problema
```

Isso vai mostrar:
1. Se o flow existe
2. Se há blocos no banco
3. Se o prompt_voz do assistente existe
4. Se há múltiplos flows para o mesmo assistente

### Passo 3: Verificar se o prompt_voz tem estrutura de blocos

O código procura por padrões como:
- `[PM001]`, `[AG001]`, `[CAM001]`, `[MSG001]`, `[ENC001]`
- Ou `PM001`, `AG001`, `CAM001`, etc.

Execute esta query para verificar:

```sql
SELECT 
    id,
    LENGTH(prompt_voz) as prompt_length,
    CASE 
        WHEN prompt_voz ~* '\[(PM|AG|CAM|MSG|ENC|FER)\d+\]' THEN 'Tem estrutura com colchetes'
        WHEN prompt_voz ~* '(PM|AG|CAM|MSG|ENC|FER)\d+' THEN 'Tem estrutura sem colchetes'
        ELSE 'SEM estrutura de blocos'
    END as estrutura_detectada,
    SUBSTRING(prompt_voz, 1, 500) as preview
FROM assistentes
WHERE id = 'be63d2a6-2091-40f6-bc77-1206cc6fd091';  -- SUBSTITUA PELO ID
```

## 🎯 Possíveis Causas

### Causa 1: Prompt_voz não tem estrutura de blocos
**Solução:** O prompt precisa ter marcadores como `[PM001]`, `[AG001]`, etc.

### Causa 2: Prompt_voz está vazio
**Solução:** Verificar se o assistente tem `prompt_voz` preenchido na tabela `assistentes`

### Causa 3: Flow foi criado sem prompt_base
**Solução:** O código deveria buscar o `prompt_voz` do assistente automaticamente, mas pode estar falhando

### Causa 4: Múltiplos flows para o mesmo assistente
**Solução:** Verificar se há múltiplos flows e qual está sendo usado

## 🔄 Próximos Passos

1. **Execute o SQL de diagnóstico** e me envie os resultados
2. **Verifique os logs do servidor** quando carregar o flow
3. **Verifique se o prompt_voz tem estrutura de blocos**

## 📋 Checklist

- [ ] Flow existe no banco?
- [ ] Há blocos no banco para este flow?
- [ ] O assistente tem `prompt_voz` preenchido?
- [ ] O `prompt_voz` tem estrutura de blocos (ex: `[PM001]`)?
- [ ] Há múltiplos flows para o mesmo assistente?
- [ ] Os logs do servidor mostram algum erro?
