# 📋 Como Aplicar: Routes e Tools em flow_blocks

## 🎯 O Que Foi Criado

### 1. Migration SQL
**Arquivo**: `saas_server/supabase/ADICIONAR_ROUTES_E_TOOLS_EM_FLOW_BLOCKS.sql`

Este script:
- ✅ Adiciona campo `routes` (JSONB) em `flow_blocks`
- ✅ Cria trigger para sincronizar `flow_routes` → `flow_blocks.routes`
- ✅ Popula routes existentes nos blocos
- ✅ Cria índice GIN para performance

## 📋 Passo a Passo

### 1. Execute a Migration no Supabase

1. Abra o **Supabase SQL Editor**
2. Copie e cole o conteúdo de: `saas_server/supabase/ADICIONAR_ROUTES_E_TOOLS_EM_FLOW_BLOCKS.sql`
3. Execute o script
4. Verifique que não houve erros

### 2. Verifique o Resultado

Execute no Supabase:

```sql
-- Ver blocos de caminhos com suas routes
SELECT 
    block_key,
    block_type,
    content,
    jsonb_array_length(routes) as total_routes,
    routes
FROM flow_blocks
WHERE block_type = 'caminhos'
ORDER BY block_key;
```

**Resultado esperado**: Você deve ver o campo `routes` preenchido com um array JSON das routes.

### 3. Teste no Flow Editor

1. Abra o Flow Editor
2. Edite uma route (ex: mude o label)
3. Clique em "Salvar"
4. Verifique no Supabase que o campo `routes` foi atualizado automaticamente

## 🔍 Estrutura do Campo `routes`

Quando você olhar `flow_blocks` no Supabase, o campo `routes` terá este formato:

```json
[
  {
    "id": "uuid",
    "route_key": "CAM001_route_1",
    "label": "Confirmou que é ele",
    "ordem": 1,
    "cor": "#22c55e",
    "keywords": ["sim", "sou eu"],
    "response": "Perfeito! Em que posso ajudar?",
    "destination_type": "continuar",
    "destination_block_key": "MSG001",
    "is_fallback": false
  }
]
```

## ✅ O Que Está Funcionando Agora

1. **Tabela `flow_blocks`**:
   - Campo `routes` (JSONB) com todas as routes do bloco
   - Campo `tool_config` (JSONB) com configuração da tool
   - Sincronização automática via trigger

2. **Tabela `flow_routes`**:
   - Continua existindo (normalização)
   - Trigger sincroniza automaticamente para `flow_blocks.routes`

3. **Frontend**:
   - Continua funcionando normalmente
   - Salva em `flow_routes` via API
   - Trigger atualiza `flow_blocks.routes` automaticamente

## 🎉 Resultado Final

Agora quando você olhar `flow_blocks` no Supabase:
- ✅ Bloco CAM001 mostra suas 3 routes no campo `routes`
- ✅ Bloco de ferramenta mostra sua config no campo `tool_config`
- ✅ Tudo sincronizado automaticamente!
