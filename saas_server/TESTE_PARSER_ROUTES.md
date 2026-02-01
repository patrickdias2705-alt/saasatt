# 🔍 Teste do Parser de Routes

## Problema Identificado

O prompt tem as routes definidas assim:
```
### CAMINHOS [CAM001]

**Analisando:** `{{confirmacao_nome}}`

**É a pessoa certa?**

#### + Confirmou que é ele

**Quando o lead disser:** `sim`, `sou eu`, `isso`, `pode falar`

**Fale:**
"Perfeito! Em que posso ajudar?"

**Depois:** Continue para [MSG001]

#### x Não é a pessoa

**Quando o lead disser:** `não`, `engano`, `número errado`

**Fale:**
"Desculpe pelo engano. Até logo!"

**Depois:** Encerre em [ENC001]

#### ? Não entendi

**Quando nenhuma condicao acima for atendida**

**Fale:**
"Não entendi. Estou falando com [Nome do Lead]?"

**Depois:** Volte para [AG001] (maximo 2 tentativas)
```

## Como o Parser Funciona

O parser `extract_routes_from_section` divide a seção em subseções usando `####`:

```python
route_sections = re.split(r'\n####+', section)
```

Isso deveria dividir em:
1. Cabeçalho (antes do primeiro `####`)
2. `+ Confirmou que é ele` + conteúdo
3. `x Não é a pessoa` + conteúdo  
4. `? Não entendi` + conteúdo

## Possíveis Problemas

1. **O parser pode não estar sendo chamado** quando o flow é carregado
2. **As routes podem não estar sendo salvas** no banco
3. **O prompt pode não estar sendo parseado** quando o flow é criado

## Solução

1. Execute o script SQL: `VERIFICAR_E_INSERIR_ROUTES_CAM001.sql`
2. Verifique se as routes estão no banco
3. Se não estiverem, o script vai inserir automaticamente
4. Recarregue o Flow Editor

## Verificação Manual

Execute no Supabase SQL Editor:

```sql
-- Verificar se o bloco CAM001 existe
SELECT id, block_key, block_type, content 
FROM flow_blocks 
WHERE block_key = 'CAM001';

-- Verificar se existem routes para o CAM001
SELECT fr.*, fb.block_key 
FROM flow_routes fr
JOIN flow_blocks fb ON fb.id = fr.block_id
WHERE fb.block_key = 'CAM001'
ORDER BY fr.ordem;
```

Se não houver routes, execute o script `VERIFICAR_E_INSERIR_ROUTES_CAM001.sql`.
