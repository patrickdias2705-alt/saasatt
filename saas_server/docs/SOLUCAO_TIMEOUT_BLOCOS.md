# 🔧 Solução para Timeout ao Salvar Blocos

## Problema
Ao salvar blocos no Flow Editor, ocorre timeout (`statement timeout`) e todos os blocos desaparecem do banco de dados.

## Causa Raiz
1. **Trigger SQL ativo**: O trigger `trigger_sync_prompt_voz_on_block_change` executa uma função pesada que atualiza `prompt_voz` toda vez que um bloco é inserido/atualizado, causando timeout.
2. **Lógica de DELETE antes de INSERT**: O código antigo deletava todos os blocos ANTES de inserir os novos. Se a inserção falhasse (timeout), tudo era perdido.

## Solução Implementada

### 1. Inserção Segura (INSERT primeiro, DELETE depois)
- ✅ **Inserir blocos PRIMEIRO** em lotes pequenos (2 blocos por vez)
- ✅ **Só depois deletar** os blocos antigos que não estão na lista nova
- ✅ Se a inserção falhar, os blocos antigos são preservados

### 2. Inserção em Lotes Pequenos
- Blocos são inseridos em lotes de **2 por vez** para evitar timeout
- Se um lote falhar, tenta inserir um por um
- Logs detalhados para identificar problemas

### 3. Desabilitar Trigger (Recomendado)
Execute este SQL no Supabase antes de salvar blocos:

```sql
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
```

Ou execute o script: `supabase/garantir_trigger_desabilitado.sql`

## Como Usar

### Passo 1: Desabilitar o Trigger
Execute no Supabase SQL Editor:
```sql
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
```

### Passo 2: Salvar Blocos no Flow Editor
Agora você pode salvar normalmente. Os blocos serão:
- Inseridos em lotes pequenos (2 por vez)
- Se algum lote falhar, tenta inserir individualmente
- Blocos antigos só são deletados após inserção bem-sucedida

### Passo 3: Verificar Status
```sql
SELECT 
    tgname,
    CASE WHEN tgenabled = 'D' THEN 'DESABILITADO' ELSE 'ATIVO' END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';
```

## Logs do Servidor
Ao salvar, você verá logs como:
```
save_flow: 📥 Inserindo 5 blocos em lotes de 2 para evitar timeout...
save_flow: ✅ Lote 1-2 inserido (2 blocos)
save_flow: ✅ Lote 3-4 inserido (2 blocos)
save_flow: ✅ Lote 5-5 inserido (1 blocos)
save_flow: ✅ 5 blocos inseridos com sucesso. Agora deletando blocos antigos...
```

## Reabilitar Trigger (Opcional)
Se quiser reabilitar o trigger depois (não recomendado enquanto estiver editando):
```sql
ALTER TABLE flow_blocks ENABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
```

**⚠️ ATENÇÃO**: Não reabilite o trigger enquanto estiver inserindo blocos, pois causará timeout novamente.

## Troubleshooting

### Blocos ainda desaparecem?
1. Verifique se o trigger está desabilitado (execute `garantir_trigger_desabilitado.sql`)
2. Verifique os logs do servidor para ver quantos blocos foram inseridos
3. Execute `verificar_blocos_atuais.sql` para ver o estado atual do banco

### Timeout ainda ocorre?
- Reduza o tamanho do lote de 2 para 1 bloco por vez (edite `batch_size = 1` em `flow_service.py`)
- Verifique se há outros triggers ou constraints pesadas na tabela `flow_blocks`
