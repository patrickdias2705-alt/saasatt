# Adaptar assist-tool-craft para usar APIs do banco (/api/flows)

O editor **assist-tool-craft** (servido em `/flow`) precisa ser adaptado para:

1. **Carregar** do banco via **GET /api/flows/by-assistant/{assistente_id}?tenant_id=...**
2. **Salvar** no banco via **POST /api/flows/save**
3. **Remover dados mockados/falsos** e usar só o que vem do banco

---

## O que fazer no código do assist-tool-craft

### 1. Ao abrir o editor (onLoad/init)

**Ler da URL:**
```javascript
const params = new URLSearchParams(window.location.search);
const assistenteId = params.get('assistente_id') || params.get('assistant_id') || '';
const tenantId = params.get('tenant_id') || '';
```

**Carregar flow do banco:**
```javascript
async function loadFlow() {
  const url = `/api/flows/by-assistant/${encodeURIComponent(assistenteId)}?tenant_id=${encodeURIComponent(tenantId)}`;
  const res = await fetch(url);
  const data = await res.json();
  
  // data.flow = { id, name, prompt_base, ... }
  // data.blocks = [{ id, block_key, block_type, content, next_block_key, order_index, position_x, position_y, ... }]
  // data.routes = [{ id, block_id, route_key, label, keywords, destination_block_key, ... }]
  
  // Converter para o formato do canvas do assist-tool-craft
  const nodes = data.blocks.map(b => ({
    id: b.block_key,  // ou b.id, conforme o canvas espera
    type: b.block_type,
    content: b.content,
    position: { x: b.position_x || 0, y: b.position_y || 0 },
    // ... outros campos conforme o canvas precisa
  }));
  
  // Renderizar nodes no canvas
  renderNodes(nodes);
  
  // Para rotas (caminhos): mapear routes por block_id
  const routesByBlock = {};
  data.routes.forEach(r => {
    const block = data.blocks.find(b => b.id === r.block_id);
    if (block && block.block_key) {
      if (!routesByBlock[block.block_key]) routesByBlock[block.block_key] = [];
      routesByBlock[block.block_key].push({
        key: r.route_key,
        label: r.label,
        keywords: r.keywords || [],
        destination: r.destination_block_key,
        // ...
      });
    }
  });
}
```

### 2. Ao salvar (onSave)

**Converter nodes do canvas para o formato da API:**
```javascript
async function saveFlow() {
  const nodes = getNodesFromCanvas(); // como o canvas retorna os nodes
  
  const blocks = nodes.map((node, idx) => ({
    block_key: node.id || node.block_key || `BLK${idx}`,
    block_type: node.type,
    content: node.content || '',
    next_block_key: node.nextNodeId || null,
    order_index: idx,
    position_x: node.position?.x || 0,
    position_y: node.position?.y || 0,
    // ... outros campos conforme o tipo (variable_name, tool_type, etc.)
  }));
  
  // Rotas: se o canvas tem edges/connections para caminhos
  const routes = [];
  // ... mapear rotas do canvas para o formato da API
  
  const flowId = currentFlowId; // do loadFlow acima (data.flow.id)
  
  const res = await fetch('/api/flows/save', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      flow_id: flowId,
      blocks: blocks,
      routes: routes
    })
  });
  
  const result = await res.json();
  // result = { success: true, version: N }
}
```

### 3. Remover dados mockados

- Buscar no código por arrays/objetos hardcoded (ex.: `const mockBlocks = [...]`, `const sampleFlow = {...}`)
- Remover esses dados e usar só o que vem de `loadFlow()`

### 4. Identificação automática de blocos

- O canvas já deve identificar tipos de nodes (primeira_mensagem, mensagem, aguardar, caminhos, ferramenta, encerrar)
- Ao carregar do banco, usar `block_type` para renderizar o node correto no canvas
- As rotas (caminhos) já vêm do banco em `data.routes`; mapear para edges/connections do canvas

---

## Estrutura de dados esperada

**GET /api/flows/by-assistant/{id}** retorna:
```json
{
  "flow": {
    "id": "uuid",
    "name": "Flow do assistente...",
    "prompt_base": "# IA DE VOZ...",
    "version": 1
  },
  "blocks": [
    {
      "id": "uuid",
      "block_key": "PM001",
      "block_type": "primeira_mensagem",
      "content": "Olá! ...",
      "next_block_key": "AG001",
      "order_index": 1,
      "position_x": 100,
      "position_y": 50
    },
    // ...
  ],
  "routes": [
    {
      "id": "uuid",
      "block_id": "uuid-do-CAM001",
      "route_key": "confirmou",
      "label": "Confirmou",
      "keywords": ["sim", "sou eu"],
      "destination_block_key": "MSG001",
      "ordem": 1,
      "cor": "#22c55e"
    },
    // ...
  ]
}
```

**POST /api/flows/save** espera:
```json
{
  "flow_id": "uuid",
  "blocks": [
    {
      "block_key": "PM001",
      "block_type": "primeira_mensagem",
      "content": "...",
      "next_block_key": "AG001",
      "order_index": 1,
      "position_x": 100,
      "position_y": 50
    }
  ],
  "routes": [
    {
      "block_key": "CAM001",  // bloco pai
      "route_key": "confirmou",
      "label": "...",
      "keywords": [...],
      "destination_block_key": "MSG001",
      "ordem": 1,
      "cor": "#22c55e"
    }
  ]
}
```

---

## Próximos passos

1. Abrir o código do assist-tool-craft (pasta `/Users/patrickdiasparis/Downloads/assist-tool-craft-main/`)
2. Localizar onde ele carrega dados (função de load/init)
3. Substituir por `GET /api/flows/by-assistant/{id}?tenant_id=...`
4. Localizar onde ele salva (função de save)
5. Substituir por `POST /api/flows/save`
6. Remover dados mockados/hardcoded
7. Testar: abrir Flow Editor para um assistente e ver se carrega do banco
