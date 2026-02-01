# ⚡ Endpoint Simples: Atualizar Um Bloco Específico

## Novo Endpoint Criado

**`PATCH /api/flows/{flow_id}/blocks/{block_key}`**

Este endpoint atualiza **apenas um bloco específico** na tabela `flow_blocks`, sem processar todos os blocos.

## Como Usar

### Exemplo de Requisição

```javascript
// Quando você editar apenas o bloco "ENC001" (encerrar)
const response = await fetch(`/api/flows/${flowId}/blocks/ENC001`, {
  method: 'PATCH',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    block_key: 'ENC001',
    block_type: 'encerrar',
    content: 'Novo conteúdo do bloco de encerrar',
    next_block_key: null,
    order_index: 4,
    position_x: 100,
    position_y: 200,
    // ... outros campos opcionais
  })
});

const result = await response.json();
// result = { success: true, block_key: 'ENC001', action: 'updated', data: {...} }
```

### Vantagens

✅ **Mais Simples**: Apenas atualiza o bloco que você editou  
✅ **Mais Rápido**: Não processa todos os blocos  
✅ **Mais Seguro**: Não há risco de perder outros blocos  
✅ **Direto**: Acesso direto à tabela `flow_blocks`  

## Comparação

### Método Antigo (`POST /api/flows/save`)
- ❌ Processa TODOS os blocos
- ❌ Compara cada bloco com o banco
- ❌ Mais complexo e lento
- ❌ Pode dar timeout com muitos blocos

### Método Novo (`PATCH /api/flows/{flow_id}/blocks/{block_key}`)
- ✅ Atualiza APENAS o bloco editado
- ✅ Simples UPDATE direto no banco
- ✅ Muito mais rápido
- ✅ Não depende de trigger

## Quando Usar Cada Método

### Use `PATCH /flows/{flow_id}/blocks/{block_key}` quando:
- Você editou apenas **um bloco específico**
- Você quer atualização **rápida e direta**
- Você não quer processar todos os blocos

### Use `POST /flows/save` quando:
- Você fez **múltiplas mudanças** em vários blocos
- Você quer **sincronizar tudo** de uma vez
- Você deletou ou adicionou blocos

## Exemplo de Integração no Frontend

```typescript
// Quando o usuário edita um bloco no Flow Editor
async function updateBlock(blockKey: string, blockData: FlowBlock) {
  const flowId = currentFlowId;
  
  try {
    const response = await fetch(`/api/flows/${flowId}/blocks/${blockKey}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        block_key: blockKey,
        block_type: blockData.type,
        content: blockData.content,
        next_block_key: blockData.nextBlock,
        order_index: blockData.orderIndex,
        position_x: blockData.position.x,
        position_y: blockData.position.y,
        // ... outros campos
      })
    });
    
    if (!response.ok) {
      throw new Error('Erro ao atualizar bloco');
    }
    
    const result = await response.json();
    console.log(`✅ Bloco ${blockKey} ${result.action === 'updated' ? 'atualizado' : 'inserido'}`);
    
  } catch (error) {
    console.error('❌ Erro ao atualizar bloco:', error);
  }
}
```

## Resposta do Endpoint

### Sucesso (UPDATE)
```json
{
  "success": true,
  "block_key": "ENC001",
  "action": "updated",
  "data": {
    "id": "uuid-do-bloco",
    "block_key": "ENC001",
    "block_type": "encerrar",
    "content": "Novo conteúdo",
    ...
  }
}
```

### Sucesso (INSERT - bloco novo)
```json
{
  "success": true,
  "block_key": "ENC001",
  "action": "inserted",
  "data": {
    "id": "uuid-do-bloco",
    ...
  }
}
```

### Erro
```json
{
  "detail": "Erro ao atualizar bloco: ..."
}
```

## Próximos Passos

1. ✅ Endpoint criado e funcionando
2. ⏳ Adaptar frontend para usar este endpoint quando editar um bloco
3. ⏳ Manter `/flows/save` para quando fizer múltiplas mudanças
