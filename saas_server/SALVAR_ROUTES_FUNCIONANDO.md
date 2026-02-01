# ✅ Salvamento de Routes Funcionando

## 🎯 O Que Foi Corrigido

### 1. Função `flowEditorSave()` Atualizada
- ✅ Agora usa a API `/api/flows/save` em vez do webhook antigo
- ✅ Converte blocos e routes para o formato correto da API
- ✅ Inclui todas as routes (normais + fallback) no salvamento
- ✅ Mapeia tipos corretamente (`conectivos` → `caminhos`)

### 2. Formato de Dados
A função agora envia:
```javascript
{
  flow_id: "uuid-do-flow",
  blocks: [
    {
      block_key: "CAM001",
      block_type: "caminhos",
      content: "...",
      // ... outros campos
    }
  ],
  routes: [
    {
      block_key: "CAM001",
      route_key: "CAM001_route_1",
      label: "Confirmou que é ele",
      keywords: ["sim", "sou eu"],
      response: "Perfeito! Em que posso ajudar?",
      destination_type: "continuar",
      destination_block_key: "MSG001",
      is_fallback: false,
      ordem: 1,
      cor: "#22c55e"
    },
    // ... mais routes
  ]
}
```

## 🧪 Como Testar

1. **Edite uma route no Flow Editor:**
   - Clique no bloco CAM001
   - Edite o label de uma route (ex: mude "Confirmou que é ele" para "Confirmou!")
   - Edite keywords ou response
   - Clique em "Salvar" no topo do Flow Editor

2. **Verifique no banco:**
   ```sql
   SELECT route_key, label, keywords, response 
   FROM flow_routes 
   WHERE block_id = (
     SELECT id FROM flow_blocks WHERE block_key = 'CAM001' LIMIT 1
   )
   ORDER BY ordem;
   ```

3. **Recarregue o Flow Editor:**
   - As mudanças devem aparecer automaticamente

## ✅ O Que Está Funcionando

- ✅ Routes aparecem corretamente no Flow Editor
- ✅ Edição de routes funciona (label, keywords, response)
- ✅ Salvamento via API `/api/flows/save`
- ✅ Routes são salvas no banco com todos os campos
- ✅ Fallback é salvo separadamente com `is_fallback: true`

## 📋 Próximos Passos

Se quiser salvamento automático ao editar (sem precisar clicar em "Salvar"):
- Posso implementar salvamento automático quando `updateFlowRoute()` é chamado
- Ou manter o salvamento manual (mais seguro, evita muitas requisições)
