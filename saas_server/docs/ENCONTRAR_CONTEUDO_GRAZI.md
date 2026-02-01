# Encontrar Conteúdo da Grazi no Banco

## Resultado da Verificação Anterior

Encontrei um bloco `PM001` com conteúdo:
```
"Olá! Aqui é a [Nome da IA]. Estou falando com [Nome do Lead]?"
```

Mas você mencionou que está vendo:
```
"Olá! Sou a Grazi, assistente virtual da Salesdever. Vi sua aplicação e adoraria conhecer melhor seu cenário. Tudo bem?"
```

## Busca Mais Específica

Execute este SQL para buscar o conteúdo exato:

```sql
saas_server/supabase/buscar_conteudo_grazi_exato.sql
```

Este script busca:
1. 🔍 Blocos com conteúdo da Grazi (texto exato)
2. 🔍 Prompt_base com conteúdo da Grazi
3. 🔍 Todos os blocos de um flow específico (substitua o assistente_id)
4. 🔍 Últimos 50 blocos criados

## Como Usar

### Passo 1: Execute a busca geral
Execute o script completo para ver todos os blocos com conteúdo da Grazi.

### Passo 2: Se souber o assistente_id
Na query 3, substitua `'ASSISTENTE_ID_AQUI'` pelo `assistente_id` do assistente que você está editando:

```sql
WHERE f.assistente_id = 'e7dfde93-35d2-44ee-8c4b-589fd408d00b'  -- Exemplo
```

### Passo 3: Verifique o Console do Navegador

Quando abrir o Flow Editor, verifique no Console (F12):

1. Procure por `[FlowEditor] 📋 Blocos do banco:`
2. Veja o `content_preview` de cada bloco
3. Se aparecer conteúdo da Grazi, significa que está no banco

## Se Encontrar Blocos com Conteúdo da Grazi

Esses blocos foram criados anteriormente e estão salvos no banco. Você pode:

### Opção 1: Deletar Manualmente no Editor
1. Abra o Flow Editor
2. Delete os blocos com conteúdo da Grazi
3. Salve o flow

### Opção 2: Atualizar via SQL
```sql
-- Atualizar blocos com conteúdo da Grazi para vazio
UPDATE flow_blocks
SET content = ''
WHERE content LIKE '%Grazi%'
   OR content LIKE '%assistente virtual da Salesdever%'
   OR content LIKE '%Vi sua aplicação%';
```

Execute o SQL e me envie o resultado completo!
