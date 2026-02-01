# Como limpar blocos padrão de flows existentes

## Problema

Se você editou um assistente antes de removermos a criação automática de blocos padrão, o flow desse assistente pode ter blocos padrão salvos no banco:
- `PM001` - Primeira Mensagem padrão
- `AG001` - Aguardar padrão
- `CAM001` - Caminhos padrão
- `MSG001` - Mensagem padrão
- `ENC001` - Encerrar padrão

Esses blocos aparecem sempre que você abre o Flow Editor para aquele assistente.

## Solução

### Opção 1: Deletar manualmente no editor
1. Abra o Flow Editor para o assistente
2. Delete cada bloco padrão manualmente (clique no bloco → delete)
3. Salve o flow

### Opção 2: Limpar via SQL (recomendado se tem muitos flows)

1. Abra o **SQL Editor** do Supabase
2. Execute o script: `supabase/limpar_blocos_padrao.sql`
3. Isso vai deletar todos os blocos padrão de todos os flows

**⚠️ ATENÇÃO:** Este script deleta permanentemente os blocos padrão. Se você editou algum desses blocos e quer mantê-los, **NÃO execute o script**. Delete manualmente apenas os que não quer.

## Verificar se um flow tem blocos padrão

Execute no SQL Editor:

```sql
SELECT 
  f.name as flow_name,
  f.assistente_id,
  fb.block_key,
  fb.block_type,
  fb.content
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.block_key IN ('PM001', 'AG001', 'CAM001', 'MSG001', 'ENC001')
ORDER BY f.name, fb.order_index;
```

Isso mostra quais flows têm blocos padrão e quais são.

## Depois de limpar

1. Reinicie o servidor FastAPI (se estiver rodando)
2. Abra o Flow Editor para um assistente
3. Deve aparecer o estado vazio (sem blocos)
4. Você pode criar seus próprios blocos do zero
