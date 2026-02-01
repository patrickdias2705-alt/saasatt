# 🤖 PROMPT DIRETO PARA CLAUDE AI - Copie e Cole

---

Olá Claude! Preciso da sua ajuda para implementar um sistema de **patch cirúrgico de prompts** usando IA generativa.

## CONTEXTO

Tenho uma plataforma SaaS onde usuários editam fluxos de conversa para assistentes de voz (IA que faz ligações telefônicas). Quando um usuário edita um bloco específico no editor visual, preciso atualizar **APENAS aquela seção** em um prompt grande (5000+ caracteres), mantendo todo o resto intacto.

## ESTRUTURA DO BANCO

**Tabela `assistentes`:**
- `id` (UUID)
- `prompt_voz` (TEXT) - ⭐ Prompt completo grande em Markdown

**Tabela `flows`:**
- `id` (UUID)
- `assistente_id` (UUID) - FK para assistentes

**Tabela `flow_blocks`:**
- `id` (UUID)
- `flow_id` (UUID) - FK para flows
- `block_key` (TEXT) - ⭐ ID único: "ENC001", "MSG001", "AG001", etc.
- `block_type` (TEXT) - ⭐ Tipo: "encerrar", "mensagem", "aguardar", "caminhos", "primeira_mensagem"
- `content` (TEXT) - ⭐ Conteúdo que precisa ser atualizado no prompt_voz
- `next_block_key` (TEXT) - Próximo bloco
- `variable_name` (TEXT) - Para blocos "aguardar"

## FORMATO DO PROMPT

O `prompt_voz` é um texto Markdown grande assim:

```markdown
# PROMPT - FLOW DO ASSISTENTE

## FLUXO DA CONVERSA

### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logo!"

---

### MENSAGEM [MSG001]

**Fale:**

"Olá! Como posso ajudar?"
```

## O QUE PRECISO

Quando `flow_blocks` é atualizado, preciso:

1. **Identificar** a seção no `prompt_voz` usando `block_key` e `block_type`
2. **Localizar** limites exatos da seção (início e fim)
3. **Formatar** nova seção com os dados atualizados
4. **Substituir APENAS** aquela seção
5. **Manter TODO o resto** do prompt igual

## PADRÕES DE IDENTIFICAÇÃO

| Tipo | Padrão no Prompt |
|------|------------------|
| `primeira_mensagem` | `### ABERTURA DA LIGACAO` |
| `mensagem` | `### MENSAGEM [BLOCK_KEY]` |
| `aguardar` | `### AGUARDAR [BLOCK_KEY]` |
| `caminhos` | `### CAMINHOS [BLOCK_KEY]` |
| `encerrar` | `### ENCERRAR [BLOCK_KEY]: finalizar` ou `### ENCERRAR [BLOCK_KEY]` |

## FORMATO DE CADA TIPO

### `encerrar`:
```markdown
### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"[conteúdo]"
```

### `mensagem`:
```markdown
### MENSAGEM [MSG001]

**Fale:**

"[conteúdo]"
```

### `aguardar`:
```markdown
### AGUARDAR [AG001]

**Escute a resposta do lead.** 
Salvar resposta do lead em: `{{variable_name}}`

**Depois:** Va para [next_block_key]
```

### `primeira_mensagem`:
```markdown
### ABERTURA DA LIGACAO

**Ao iniciar a ligacao, fale:**

"[conteúdo]"

**Depois:** Va para [next_block_key]
```

### `caminhos`:
```markdown
### CAMINHOS [CAM001]

**Analisando:** `{{analyze_variable}}`

[rotas...]
```

## EXEMPLO PRÁTICO

**Input:**
- Prompt original com `"Desculpe pelo engano. Até logo!"` na seção ENC001
- Novo conteúdo: `"Desculpe pelo engano. Até logooooo!"`

**Output:**
- Prompt completo com APENAS essa linha mudada
- Todo o resto permanece igual

## REGRAS ABSOLUTAS

✅ MANTER: Todo texto antes/depois da seção
✅ MANTER: Formatação, espaçamentos, separadores (`---`)
✅ SUBSTITUIR: Apenas a seção específica
❌ NÃO ADICIONAR: Texto novo
❌ NÃO REMOVER: Nada além da seção alvo
❌ NÃO REFORMATAR: Outras seções

## CASOS ESPECIAIS

- Se bloco não encontrado: retornar prompt original sem alterações
- Se múltiplas ocorrências: substituir a primeira
- Se formato variado: ser tolerante mas manter estilo original

## TAREFA

Crie uma função Python que:

1. Recebe: `original_prompt`, `block_key`, `block_type`, `new_content`, `next_block_key` (opcional), `variable_name` (opcional)
2. Identifica a seção no prompt
3. Formata nova seção corretamente
4. Substitui APENAS aquela seção
5. Retorna prompt completo atualizado

Use a biblioteca `anthropic` (Claude) ou `openai` (GPT) para fazer o processamento com IA.

**Formato de resposta:** Apenas o prompt completo atualizado, sem explicações.

Pode criar também um endpoint FastAPI que expõe essa funcionalidade.

---

**Obrigado! 🚀**
