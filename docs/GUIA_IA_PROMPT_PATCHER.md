# 🤖 Guia Completo: Sistema de Patch Inteligente com IA

## 📋 Visão Geral

Este sistema usa IA generativa (Claude/GPT) para fazer atualizações **cirúrgicas** em prompts grandes, substituindo apenas a seção específica de um bloco sem alterar o resto do prompt.

## 🎯 Por que usar IA ao invés de SQL?

### Problemas com SQL/Regex:
- ❌ Frágil a variações de formato
- ❌ Quebra com pequenas mudanças na estrutura
- ❌ Difícil de manter quando o formato muda
- ❌ Requer múltiplas funções SQL complexas

### Vantagens da IA:
- ✅ **Tolerante a variações** - entende contexto, não apenas padrões
- ✅ **Mais inteligente** - identifica seções mesmo com formatação diferente
- ✅ **Mais fácil de manter** - mudanças no formato não quebram o sistema
- ✅ **Mais precisa** - entende a estrutura sem depender de regex exato

## 🏗️ Arquitetura

```
flow_blocks (UPDATE) 
    ↓
Trigger PostgreSQL (opcional - pode chamar API)
    ↓
API FastAPI (/api/flows/ai-patch-prompt)
    ↓
Serviço Python (ai_prompt_patcher.py)
    ↓
Chama IA (Claude/GPT) com prompt estruturado
    ↓
IA retorna prompt atualizado
    ↓
UPDATE assistentes.prompt_voz
```

## 📦 Instalação

### 1. Instalar dependências Python

```bash
cd saas_server
pip install anthropic openai
```

### 2. Configurar variáveis de ambiente

Adicione ao seu `.env` ou variáveis de ambiente:

```bash
# Para usar Claude (Anthropic)
ANTHROPIC_API_KEY=sk-ant-...

# OU para usar OpenAI (GPT)
OPENAI_API_KEY=sk-...

# Opcional: escolher modelo específico
ANTHROPIC_MODEL=claude-3-haiku-20240307  # Mais barato e rápido
# ANTHROPIC_MODEL=claude-3-opus-20240229  # Mais inteligente, mais caro

OPENAI_MODEL=gpt-4o-mini  # Mais barato
# OPENAI_MODEL=gpt-4o  # Mais inteligente
```

### 3. Obter API Keys

#### Anthropic (Claude):
1. Acesse: https://console.anthropic.com/
2. Crie uma conta ou faça login
3. Vá em "API Keys"
4. Crie uma nova chave
5. Copie e cole no `.env`

#### OpenAI (GPT):
1. Acesse: https://platform.openai.com/api-keys
2. Crie uma conta ou faça login
3. Crie uma nova chave
4. Copie e cole no `.env`

## 🚀 Como Usar

### Opção 1: Via API REST (Recomendado)

```bash
POST http://localhost:8080/api/flows/ai-patch-prompt
Content-Type: application/json

{
  "assistente_id": "e7dfde93-35d2-44ee-8c4b-589fd408d00b",
  "block_key": "ENC001",
  "block_type": "encerrar",
  "new_content": "Desculpe pelo engano. Até logooooo!",
  "provider": "anthropic"
}
```

**Resposta:**
```json
{
  "success": true,
  "updated_prompt": "...",
  "prompt_length_before": 5000,
  "prompt_length_after": 5010,
  "error": null
}
```

### Opção 2: Integrar no Trigger PostgreSQL

Você pode modificar o trigger SQL para chamar a API quando necessário:

```sql
-- Exemplo: Chamar API quando o trigger SQL falhar
CREATE OR REPLACE FUNCTION sync_prompt_voz_with_ai_fallback()
RETURNS TRIGGER AS $$
DECLARE
    v_updated_prompt TEXT;
    v_api_response JSONB;
BEGIN
    -- Tentar primeiro com SQL (método atual)
    v_updated_prompt := patch_block_section_in_prompt(...);
    
    -- Se não funcionou, chamar API com IA
    IF v_updated_prompt = OLD.prompt_voz THEN
        -- Chamar API via pg_net (extensão Supabase)
        SELECT content INTO v_api_response
        FROM http((
            'POST',
            'http://localhost:8080/api/flows/ai-patch-prompt',
            ARRAY[
                http_header('Content-Type', 'application/json')
            ],
            'application/json',
            json_build_object(
                'assistente_id', NEW.assistente_id,
                'block_key', NEW.block_key,
                'block_type', NEW.block_type,
                'new_content', NEW.content,
                'provider', 'anthropic'
            )::text
        )::http_request);
        
        -- Extrair prompt atualizado da resposta
        v_updated_prompt := v_api_response->>'updated_prompt';
    END IF;
    
    -- Atualizar prompt_voz
    UPDATE assistentes SET prompt_voz = v_updated_prompt WHERE id = NEW.assistente_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Opção 3: Usar diretamente no Python

```python
from saas_tools.services.ai_prompt_patcher import patch_prompt_with_ai

# Fazer patch
updated_prompt = patch_prompt_with_ai(
    original_prompt=assistant["prompt_voz"],
    block_key="ENC001",
    block_type="encerrar",
    new_content="Desculpe pelo engano. Até logooooo!",
    provider="anthropic"
)

# Atualizar no banco
supabase.table("assistentes").update({
    "prompt_voz": updated_prompt
}).eq("id", assistente_id).execute()
```

## 🧪 Testando

### 1. Teste manual via curl

```bash
curl -X POST http://localhost:8080/api/flows/ai-patch-prompt \
  -H "Content-Type: application/json" \
  -d '{
    "assistente_id": "e7dfde93-35d2-44ee-8c4b-589fd408d00b",
    "block_key": "ENC001",
    "block_type": "encerrar",
    "new_content": "Desculpe pelo engano. Até logooooo!",
    "provider": "anthropic"
  }'
```

### 2. Teste via Python

```python
import requests

response = requests.post(
    "http://localhost:8080/api/flows/ai-patch-prompt",
    json={
        "assistente_id": "e7dfde93-35d2-44ee-8c4b-589fd408d00b",
        "block_key": "ENC001",
        "block_type": "encerrar",
        "new_content": "Desculpe pelo engano. Até logooooo!",
        "provider": "anthropic"
    }
)

print(response.json())
```

## 💰 Custos

### Claude (Anthropic)
- **Haiku**: ~$0.25 por 1M tokens de entrada, $1.25 por 1M tokens de saída
- **Opus**: ~$15 por 1M tokens de entrada, $75 por 1M tokens de saída

**Estimativa por patch:**
- Prompt médio: ~5.000 tokens
- Resposta: ~5.000 tokens
- **Custo com Haiku**: ~$0.0075 por patch (menos de 1 centavo)
- **Custo com Opus**: ~$0.45 por patch

### OpenAI (GPT)
- **GPT-4o-mini**: ~$0.15 por 1M tokens de entrada, $0.60 por 1M tokens de saída
- **GPT-4o**: ~$5 por 1M tokens de entrada, $15 por 1M tokens de saída

**Estimativa por patch:**
- **Custo com GPT-4o-mini**: ~$0.00375 por patch (menos de meio centavo)
- **Custo com GPT-4o**: ~$0.10 por patch

## ⚙️ Configuração Avançada

### Escolher modelo baseado no tamanho do prompt

```python
def get_model_for_prompt(prompt_length: int) -> str:
    """Escolhe modelo baseado no tamanho do prompt"""
    if prompt_length < 10000:
        return "claude-3-haiku-20240307"  # Mais barato para prompts pequenos
    else:
        return "claude-3-sonnet-20240229"  # Mais inteligente para prompts grandes
```

### Cache de resultados

```python
from functools import lru_cache

@lru_cache(maxsize=100)
def cached_patch(original_prompt_hash: str, block_key: str, new_content: str) -> str:
    """Cache de patches para evitar chamadas duplicadas"""
    return patch_prompt_with_ai(...)
```

### Retry com fallback

```python
def patch_with_retry(original_prompt: str, block_key: str, block_type: str, 
                    new_content: str, max_retries: int = 3) -> str:
    """Tenta fazer patch com retry e fallback"""
    for attempt in range(max_retries):
        try:
            return patch_prompt_with_ai(
                original_prompt, block_key, block_type, new_content,
                provider="anthropic"
            )
        except Exception as e:
            if attempt == max_retries - 1:
                # Última tentativa: usar OpenAI como fallback
                return patch_prompt_with_ai(
                    original_prompt, block_key, block_type, new_content,
                    provider="openai"
                )
            time.sleep(2 ** attempt)  # Exponential backoff
```

## 🔍 Debugging

### Ver logs

```python
import logging
logging.basicConfig(level=logging.INFO)
```

Os logs mostrarão:
- Quando o patch é iniciado
- Qual bloco está sendo atualizado
- Se o patch foi bem-sucedido
- Tamanhos antes/depois

### Verificar se a IA encontrou a seção

A IA retorna o prompt completo. Compare com o original:

```python
original = assistant["prompt_voz"]
updated = response["updated_prompt"]

# Verificar se mudou
if original != updated:
    print("✅ Patch aplicado com sucesso")
    # Ver diferença
    import difflib
    diff = difflib.unified_diff(original.splitlines(), updated.splitlines())
    for line in diff:
        print(line)
else:
    print("⚠️ Prompt não mudou - IA pode não ter encontrado a seção")
```

## 🚨 Troubleshooting

### Erro: "ANTHROPIC_API_KEY não configurada"
- Verifique se a variável de ambiente está definida
- Reinicie o servidor após adicionar a variável

### Erro: "Assistente não encontrado"
- Verifique se o `assistente_id` está correto
- Verifique se o assistente tem `prompt_voz` preenchido

### IA não está atualizando o prompt
- Verifique os logs para ver o que a IA retornou
- Pode ser que o formato do bloco no prompt original seja muito diferente
- Tente usar um modelo mais inteligente (Opus ao invés de Haiku)

### Custo muito alto
- Use modelos mais baratos (Haiku, GPT-4o-mini)
- Implemente cache para evitar chamadas duplicadas
- Considere usar SQL para casos simples e IA apenas quando necessário

## 📚 Referências

- [Anthropic API Docs](https://docs.anthropic.com/)
- [OpenAI API Docs](https://platform.openai.com/docs)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [FastAPI Docs](https://fastapi.tiangolo.com/)

## ✅ Checklist de Implementação

- [ ] Instalar dependências (`anthropic` ou `openai`)
- [ ] Configurar API keys no `.env`
- [ ] Testar endpoint `/api/flows/ai-patch-prompt`
- [ ] Verificar logs de sucesso/erro
- [ ] (Opcional) Integrar com trigger SQL
- [ ] (Opcional) Implementar cache
- [ ] (Opcional) Configurar retry/fallback
