# Plano de Implementação: Prompt Canônico + Mapeamento de Blocos

## Objetivo
Implementar sistema onde:
- **Prompt canônico** é a fonte da verdade (texto único completo)
- **Globais** são pré-pendidas (não sobrescrevem)
- **Blocos** são uma "vista estruturada" do prompt (mapeamento bidirecional)
- **Edições** são patches locais no prompt canônico (não regeneram tudo)
- **Import** segue ordem sequencial do prompt (não reorganiza)

---

## Fase 1: Schema e Modelo de Dados (Backend)

### 1.1 Migração SQL - Adicionar campos ao `assistant_flows`
```sql
-- Adicionar colunas ao assistant_flows
ALTER TABLE public.assistant_flows
  ADD COLUMN IF NOT EXISTS prompt_master_canonical TEXT NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS block_mapping JSONB NOT NULL DEFAULT '[]'::jsonb;

-- block_mapping estrutura:
-- [
--   {
--     "block_id": "block_123",
--     "type": "primeira_mensagem",
--     "prompt_start": 0,      // offset em caracteres
--     "prompt_end": 150,     // offset em caracteres
--     "marker": "[[BLOCK:block_123]]"  // marcador opcional no texto
--   },
--   ...
-- ]
```

### 1.2 Atualizar Schemas Pydantic
- `AssistantFlowUpsert`: adicionar `prompt_master_canonical` e `block_mapping`
- Criar `PromptPatchRequest`: `block_id`, `old_text`, `new_text`, `context`

### 1.3 Atualizar `supabase_service.py`
- `get_assistant_flow()`: retornar `prompt_master_canonical` e `block_mapping`
- `upsert_assistant_flow()`: aceitar e salvar esses campos

---

## Fase 2: Import Sequencial (Backend)

### 2.1 Refatorar `parse_prompt_master()` em `assistants.py`
**Lógica atual:** agrupa por tipo (todos AGUARDE juntos)  
**Nova lógica:** leitura sequencial linha a linha

```python
def parse_prompt_master_sequential(prompt_master: str) -> Dict[str, Any]:
    """
    Parse sequencial: lê o prompt de cima pra baixo, identificando blocos na ordem.
    Retorna:
    - extracted_globals: seções globais (IDENTIDADE, PERSONALIDADE, etc.)
    - suggested_blocks: blocos na ordem do prompt
    - block_mapping: mapeamento bloco → trecho do prompt
    """
    lines = prompt_master.splitlines()
    blocks = []
    mapping = []
    current_offset = 0
    
    # 1. Separar globais (seções que NÃO viram blocos)
    globals_sections = extract_global_sections(prompt_master)
    
    # 2. Processar linha a linha procurando:
    #    - Frases entre aspas → bloco "texto" ou "primeira_mensagem"
    #    - "AGUARDE" / "Aguardar" → bloco "aguardar"
    #    - "ENCERRAR" → bloco "encerrar"
    #    - "CHAME tool X" → bloco "tool"
    
    for i, line in enumerate(lines):
        # Detectar tipo de bloco nesta linha
        block_type, content = detect_block_in_line(line)
        if block_type:
            block_id = f"block_{len(blocks)}"
            start = current_offset
            end = current_offset + len(line)
            
            blocks.append({
                "id": block_id,
                "type": block_type,
                "content": content,
            })
            
            mapping.append({
                "block_id": block_id,
                "type": block_type,
                "prompt_start": start,
                "prompt_end": end,
                "line_number": i + 1,
            })
        
        current_offset += len(line) + 1  # +1 para \n
    
    return {
        "extracted_globals": globals_sections,
        "suggested_blocks": blocks,
        "block_mapping": mapping,
    }
```

### 2.2 Atualizar endpoint `/prompt-import/parse`
- Usar `parse_prompt_master_sequential()` em vez de `parse_prompt_master()`
- Retornar `block_mapping` junto com `suggested_blocks`

---

## Fase 3: Patch Semântico (Backend - IA Python)

### 3.1 Criar serviço de patch semântico
**Arquivo:** `saas_server/saas_tools/services/prompt_patcher.py`

```python
from typing import Dict, Any, Optional
import openai  # ou outro LLM provider

def patch_prompt_canonical(
    prompt_canonical: str,
    block_id: str,
    old_text: str,
    new_text: str,
    block_mapping: list,
    context: Optional[str] = None
) -> Dict[str, Any]:
    """
    Usa IA para fazer patch localizado no prompt canônico.
    
    Encontra o trecho correspondente ao block_id no prompt_canonical,
    substitui old_text por new_text mantendo contexto e ordem.
    
    Retorna:
    - updated_prompt: prompt canônico atualizado
    - updated_mapping: mapeamento atualizado (offsets podem mudar)
    """
    # 1. Encontrar trecho no prompt usando block_mapping
    block_info = next((m for m in block_mapping if m["block_id"] == block_id), None)
    if not block_info:
        raise ValueError(f"Block {block_id} não encontrado no mapeamento")
    
    # 2. Extrair contexto ao redor (ex: 200 chars antes/depois)
    start = max(0, block_info["prompt_start"] - 200)
    end = min(len(prompt_canonical), block_info["prompt_end"] + 200)
    context_snippet = prompt_canonical[start:end]
    
    # 3. Chamar LLM para fazer substituição semântica
    prompt_llm = f"""
Você é um editor de prompts. Substitua APENAS o trecho indicado abaixo, mantendo:
- A ordem do texto
- O contexto ao redor
- O estilo e formatação

CONTEXTO:
{context_snippet}

TEXTO ANTIGO (substituir):
{old_text}

TEXTO NOVO (substituir por):
{new_text}

Retorne APENAS o texto completo do contexto com a substituição feita, sem explicações.
"""
    
    # Chamar LLM (OpenAI, Anthropic, etc.)
    updated_snippet = call_llm(prompt_llm)
    
    # 4. Reconstruir prompt completo
    updated_prompt = (
        prompt_canonical[:start] +
        updated_snippet +
        prompt_canonical[end:]
    )
    
    # 5. Recalcular offsets do mapping (se necessário)
    updated_mapping = recalculate_mapping(updated_prompt, block_mapping, block_id)
    
    return {
        "updated_prompt": updated_prompt,
        "updated_mapping": updated_mapping,
    }
```

### 3.2 Criar endpoint `/assistants/{id}/flow/patch`
**Arquivo:** `saas_server/saas_tools/api/assistants.py`

```python
@router.post("/assistants/{assistant_id}/flow/patch")
async def patch_flow_block(
    assistant_id: str,
    request: PromptPatchRequest
):
    """
    Patch localizado: atualiza apenas um bloco no prompt canônico.
    """
    # 1. Carregar flow atual
    flow = supabase_service.get_assistant_flow(assistant_id)
    if not flow:
        raise HTTPException(404, "Flow não encontrado")
    
    prompt_canonical = flow.get("prompt_master_canonical", "")
    block_mapping = flow.get("block_mapping", [])
    
    # 2. Aplicar patch semântico
    patched = prompt_patcher.patch_prompt_canonical(
        prompt_canonical=prompt_canonical,
        block_id=request.block_id,
        old_text=request.old_text,
        new_text=request.new_text,
        block_mapping=block_mapping,
        context=request.context,
    )
    
    # 3. Atualizar flow_json.blocks (sincronizar bloco editado)
    flow_json = flow.get("flow_json", {})
    blocks = flow_json.get("blocks", [])
    block_idx = next((i for i, b in enumerate(blocks) if b["id"] == request.block_id), None)
    if block_idx is not None:
        blocks[block_idx]["content"] = request.new_text
    
    # 4. Salvar no Supabase
    supabase_service.upsert_assistant_flow(
        assistant_id,
        {
            **flow_json,
            "blocks": blocks,
        },
        meta={
            "prompt_master_canonical": patched["updated_prompt"],
            "block_mapping": patched["updated_mapping"],
        }
    )
    
    return {"success": True, "updated": patched}
```

---

## Fase 4: Frontend - Flow Editor com Prompt Canônico Oculto

### 4.1 Atualizar `useFlowEditor.ts`
**Mudanças:**
- Remover `promptMaster` do estado local (agora vem do canônico)
- Adicionar `promptMasterCanonical` (somente leitura, oculto)
- Adicionar `blockMapping` (mapeamento bloco → trecho)
- `saveFlow()`: **não** salva `promptMaster` no `flow_json` (só blocos)
- Criar `patchBlock()`: chama `/flow/patch` quando bloco é editado

```typescript
// Novo hook para patch
const patchBlock = useCallback(async (
  blockId: string,
  oldText: string,
  newText: string
) => {
  if (!assistantId) return;
  
  const res = await fetch(`/api/assistants/${assistantId}/flow/patch`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      block_id: blockId,
      old_text: oldText,
      new_text: newText,
    }),
  });
  
  // Recarregar flow após patch
  await reloadFlow();
}, [assistantId]);
```

### 4.2 Atualizar `FlowEditor.tsx`
- Remover UI de edição de `promptMaster` (fica oculto)
- Quando bloco é editado → chamar `patchBlock()` em vez de `updateBlock()` direto
- Preview/Export: usar `globalsPrompt + promptMasterCanonical` (não recomposto)

### 4.3 Atualizar `previewFlow()` e `exportFlow()`
```typescript
const previewFlow = useCallback(() => {
  let preview = '=== CONFIGURAÇÕES GLOBAIS ===\n';
  preview += globalsPrompt + '\n\n';
  preview += '=== PROMPT CANÔNICO (ASSISTENTE) ===\n';
  preview += promptMasterCanonical + '\n\n';
  preview += '=== FLUXO (VISTA ESTRUTURADA) ===\n\n';
  // ... blocos como referência
}, [globalsPrompt, promptMasterCanonical, blocks]);
```

---

## Fase 5: Importador - Salvar Prompt Canônico

### 5.1 Atualizar `importador-prompt.html`
**Quando confirma import:**
- Salvar `prompt_master` original como `prompt_master_canonical`
- Salvar `block_mapping` gerado pelo parser sequencial
- `flow_json.blocks` = blocos sugeridos (vista estruturada)
- `flow_json.promptMaster` = **vazio** (não usado mais)

---

## Fase 6: Composição Final (Runtime)

### 6.1 Endpoint `/assistants/{id}/prompt/final`
**Para uso em produção (chamada da IA):**
```python
@router.get("/assistants/{assistant_id}/prompt/final")
async def get_final_prompt(assistant_id: str):
    """
    Retorna prompt final composto: globais + prompt canônico.
    Usado pela IA em runtime.
    """
    profile = supabase_service.get_assistant_profile(assistant_id)
    flow = supabase_service.get_assistant_flow(assistant_id)
    
    globals_text = compose_globals(profile)
    canonical = flow.get("prompt_master_canonical", "")
    
    final = f"{globals_text}\n\n{canonical}"
    return {"success": True, "prompt": final}
```

---

## Ordem de Implementação Recomendada

1. **Fase 1** (Schema) - Base de dados
2. **Fase 2** (Import sequencial) - Parser correto
3. **Fase 5** (Importador salva canônico) - Dados corretos no banco
4. **Fase 4** (Frontend oculta prompt) - UI ajustada
5. **Fase 3** (Patch semântico) - Edições finas
6. **Fase 6** (Composição final) - Runtime

---

## Dependências Externas

- **LLM Provider** para patch semântico:
  - OpenAI GPT-4 / GPT-3.5
  - Anthropic Claude
  - Ou modelo local (Ollama, etc.)
- **Configurar API key** em `saas_server/.env`:
  ```
  OPENAI_API_KEY=sk-...
  # ou
  ANTHROPIC_API_KEY=sk-ant-...
  ```

---

## Testes

### Teste 1: Import sequencial
- Colar prompt com ordem: saudação → texto → aguardar → texto → encerrar
- Verificar que blocos aparecem **na mesma ordem**

### Teste 2: Patch localizado
- Editar apenas saudação inicial
- Verificar que prompt canônico tem **só** a saudação alterada
- Verificar que outras partes do prompt **não mudaram**

### Teste 3: Composição final
- Ter globais preenchidas
- Ter prompt canônico
- Verificar que `/prompt/final` retorna `globais + canônico` (não recomposto)

---

## Notas de Design

- **Prompt canônico** nunca é editado diretamente pelo usuário (sempre via patches)
- **Blocos** são sempre uma "vista" do prompt canônico (não fonte da verdade)
- **Globais** são sempre pré-pendidas (não mescladas no meio do prompt)
- **Mapeamento** permite localizar trechos precisos para patches
