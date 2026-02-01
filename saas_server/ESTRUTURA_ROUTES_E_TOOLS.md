# ✅ Estrutura: Routes e Tools em flow_blocks

## 🎯 Problema Resolvido

Agora quando você olhar a tabela `flow_blocks` no Supabase, verá:
- **Blocos de caminhos (CAM001)**: Campo `routes` (JSONB) com todas as routes inline
- **Blocos de ferramenta**: Campo `tool_config` (JSONB) com configuração da tool

## 📋 Estrutura dos Campos

### 1. Campo `routes` (JSONB) - Para blocos tipo `caminhos`

```json
[
  {
    "id": "uuid",
    "route_key": "CAM001_route_1",
    "label": "Confirmou que é ele",
    "ordem": 1,
    "cor": "#22c55e",
    "keywords": ["sim", "sou eu", "isso"],
    "response": "Perfeito! Em que posso ajudar?",
    "destination_type": "continuar",
    "destination_block_key": "MSG001",
    "max_loop_attempts": 2,
    "is_fallback": false
  },
  {
    "id": "uuid",
    "route_key": "CAM001_route_2",
    "label": "Não é a pessoa",
    "ordem": 2,
    "cor": "#ef4444",
    "keywords": ["não", "engano"],
    "response": "Desculpe pelo engano. Até logo!",
    "destination_type": "encerrar",
    "destination_block_key": "ENC001",
    "max_loop_attempts": 2,
    "is_fallback": false
  },
  {
    "id": "uuid",
    "route_key": "CAM001_fallback",
    "label": "Não entendi",
    "ordem": 999,
    "cor": "#6b7280",
    "keywords": [],
    "response": "Não entendi. Estou falando com [Nome do Lead]?",
    "destination_type": "loop",
    "destination_block_key": "AG001",
    "max_loop_attempts": 2,
    "is_fallback": true
  }
]
```

### 2. Campo `tool_config` (JSONB) - Para blocos tipo `ferramenta`

```json
{
  "tool_id": "uuid-da-tool",
  "tool_name": "Buscar Dados",
  "tool_type": "buscar_dados",
  "parameters": {
    "campo": "valor",
    "outro_campo": "outro_valor"
  },
  "enabled": true
}
```

## 🔄 Sincronização Automática

### Trigger Automático
- Quando você **insere/atualiza/deleta** uma route em `flow_routes`
- O trigger **automaticamente atualiza** o campo `routes` em `flow_blocks`
- Você sempre vê as routes mais atualizadas quando olha `flow_blocks`

### Como Funciona
1. Você edita uma route no Flow Editor
2. Frontend salva em `flow_routes` via API
3. Trigger atualiza `flow_blocks.routes` automaticamente
4. Quando você olha `flow_blocks`, vê as routes atualizadas

## 🧪 Como Ver no Supabase

### Ver blocos com routes:
```sql
SELECT 
    block_key,
    block_type,
    content,
    routes,  -- ← Aqui estão as routes!
    jsonb_array_length(routes) as total_routes
FROM flow_blocks
WHERE block_type = 'caminhos';
```

### Ver blocos com tools:
```sql
SELECT 
    block_key,
    block_type,
    content,
    tool_type,
    tool_config  -- ← Aqui está a config da tool!
FROM flow_blocks
WHERE block_type = 'ferramenta';
```

## ✅ Vantagens

1. **Visibilidade**: Vê routes e tools diretamente no bloco
2. **Edição**: Pode editar o JSONB diretamente no Supabase (se necessário)
3. **Sincronização**: Trigger mantém sempre atualizado
4. **Performance**: Índice GIN para buscas rápidas
5. **Compatibilidade**: Mantém tabela `flow_routes` separada (normalização)

## 📝 Notas Importantes

- O campo `routes` é **somente leitura** via trigger
- Para editar routes, use a API `/api/flows/save` ou edite `flow_routes` diretamente
- O trigger sincroniza automaticamente `flow_routes` → `flow_blocks.routes`
- O campo `tool_config` pode ser editado diretamente ou via API
