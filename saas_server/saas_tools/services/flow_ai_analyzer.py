"""
Serviço de Análise Inteligente de Prompts usando IA
Analisa o prompt completo do assistente e cria/atualiza blocos automaticamente
Garante que blocos dentro de rotas sejam criados corretamente
"""
import os
import logging
from typing import Dict, Any, List, Optional
import json

logger = logging.getLogger(__name__)

# Importar cliente da IA (Anthropic Claude ou OpenAI)
try:
    from anthropic import Anthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False
    logger.warning("Anthropic SDK não disponível. Instale com: pip install anthropic")

try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    logger.warning("OpenAI SDK não disponível. Instale com: pip install openai")


class FlowAIAnalyzer:
    """Classe para analisar prompts usando IA e criar blocos automaticamente"""
    
    def __init__(self, provider: str = "openai"):
        """
        Inicializa o analyzer com o provedor de IA
        
        Args:
            provider: "anthropic" (Claude) ou "openai" (GPT)
        """
        self.provider = provider
        
        if provider == "anthropic" and ANTHROPIC_AVAILABLE:
            api_key = os.getenv("ANTHROPIC_API_KEY")
            if not api_key:
                raise ValueError("ANTHROPIC_API_KEY não configurada")
            self.client = Anthropic(api_key=api_key)
            self.model = os.getenv("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
        elif provider == "openai" and OPENAI_AVAILABLE:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise ValueError("OPENAI_API_KEY não configurada")
            self.client = openai.OpenAI(api_key=api_key)
            self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        else:
            raise ValueError(f"Provedor {provider} não disponível ou não configurado")
    
    def _build_system_prompt(self) -> str:
        """Constrói o prompt do sistema com as instruções para a IA"""
        return """Você é um especialista em análise de fluxos de conversa para assistentes de voz e conhece profundamente o Flow Editor.

## TAREFA
Você receberá um prompt completo de um assistente de voz (formato Markdown) e deve analisar TODOS os blocos e rotas, incluindo blocos que estão DENTRO de rotas (caminhos). Você precisa entender a estrutura completa do Flow Editor para montar corretamente.

## ⚠️ REGRA CRÍTICA - LEIA PRIMEIRO!

**CADA ROTA TEM SUA PRÓPRIA SEQUÊNCIA DE BLOCOS - NUNCA MISTURE!**

Quando um bloco CAMINHOS tem múltiplas rotas:
1. Cada rota tem um `destination_block_key` (onde a rota começa)
2. A partir desse bloco, SIGA a cadeia de `next_block_key` sequencialmente
3. TODOS os blocos nessa cadeia pertencem a ESSA rota específica
4. Quando a cadeia termina (sem next_block_key), essa rota termina
5. A próxima rota tem sua própria cadeia SEPARADA

**❌ ERRADO:** Colocar blocos da rota 1 na rota 2, ou misturar tudo no meio
**✅ CERTO:** Cada rota tem seus próprios blocos, seguindo sua própria cadeia de next_block_key

**Exemplo rápido:**
- Rota 1 vai para MSG001 → MSG001 vai para MSG002 → MSG002 vai para MSG003
- MSG001, MSG002, MSG003 pertencem TODOS à rota 1 (mesmo routeId)
- Rota 2 vai para MSG004 → MSG004 vai para MSG005
- MSG004, MSG005 pertencem TODOS à rota 2 (routeId diferente da rota 1)

## CONHECIMENTO COMPLETO DO FLOW EDITOR

### Tipos de Blocos e Como Funcionam:

#### 1. **primeira_mensagem** (PM001, PM002, etc.)
- **Função**: Primeira coisa que a IA fala ao iniciar a ligação
- **Formato no prompt**: `### ABERTURA DA LIGACAO` ou `**Ao iniciar a ligacao, fale:**`
- **Campos importantes**:
  - `content`: Texto exato que a IA fala (geralmente entre aspas)
  - `next_block_key`: Próximo bloco após a mensagem inicial
- **Exemplo**: "Olá! Estou falando com [Nome do Lead]?"
- **Sempre é o primeiro bloco** (order_index: 0)

#### 2. **mensagem** (MSG001, MSG002, etc.)
- **Função**: Mensagem normal que a IA fala durante a conversa
- **Formato no prompt**: `### MENSAGEM [MSG001]` ou `**Fale:**`
- **Campos importantes**:
  - `content`: Texto exato que a IA fala (geralmente entre aspas)
  - `next_block_key`: Próximo bloco após esta mensagem
- **Pode estar dentro de uma rota** (parentRouterId e routeId preenchidos)
- **Pode estar na sequência principal** (parentRouterId: null)

#### 3. **aguardar** (AG001, AG002, etc.)
- **Função**: IA para de falar e ESCUTA a resposta do lead
- **Formato no prompt**: `### AGUARDAR [AG001]` ou `**Escute a resposta do lead.**`
- **Campos importantes**:
  - `content`: Descrição do que está sendo aguardado (ex: "Escute a resposta do lead")
  - `variable_name`: Nome da variável onde salvar a resposta (ex: "ultima_resposta", "nome_lead")
  - `timeout_seconds`: Tempo máximo de espera (opcional)
  - `next_block_key`: Próximo bloco após receber resposta
- **Sempre salva a resposta em uma variável** para usar depois
- **Geralmente precede blocos de CAMINHOS** que analisam a resposta

#### 4. **caminhos** (CAM001, CAM002, etc.) - BLOCO CRÍTICO
- **Função**: Bloco de múltiplas rotas/condições baseadas em análise de variável
- **Formato no prompt**: `### CAMINHOS [CAM001]` ou `**Analisando:**`
- **Campos importantes**:
  - `content`: Pergunta ou contexto do bloco (ex: "É a pessoa certa?")
  - `analyze_variable`: Variável que será analisada (ex: "{{ultima_resposta}}")
  - `routes_data`: Array de rotas (OBRIGATÓRIO)
- **Estrutura de routes_data**:
  - Cada rota tem: `route_key`, `label`, `keywords`, `response`, `destination_type`, `destination_block_key`
  - Rotas normais: `is_fallback: false`, `ordem: 1, 2, 3...`
  - Fallback: `is_fallback: true`, `ordem: 999`
  - Cores padrão: Verde (#22c55e), Vermelho (#ef4444), Azul (#3b82f6), Amarelo (#eab308), Roxo (#a855f7)
- **Blocos DENTRO de rotas**: Se um bloco aparece DEPOIS de uma rota específica e ANTES do destino final, ele está DENTRO dessa rota
- **Exemplo**: Se rota 1 vai para MSG002, mas há MSG001 entre a rota e MSG002, então MSG001 está DENTRO da rota 1

#### 5. **encerrar** (ENC001, ENC002, etc.)
- **Função**: Encerra a conversa/ligação
- **Formato no prompt**: `### ENCERRAR [ENC001]` ou `**finalizar**`
- **Campos importantes**:
  - `content`: Mensagem final antes de encerrar (geralmente entre aspas)
  - `end_type`: Tipo de encerramento (opcional: "finalizar", "transferir", etc.)
- **Não tem next_block_key** (é o fim do fluxo)

#### 6. **ferramenta** (TOOL001, etc.) - OPCIONAL
- **Função**: Executa uma ferramenta/ação (buscar dados, agendar, etc.)
- **Campos importantes**:
  - `tool_type`: Tipo da ferramenta (ex: "buscar_dados", "agendar", "verificar_agenda")
  - `tool_config`: Configuração da ferramenta (JSONB)
  - `next_block_key`: Próximo bloco após executar ferramenta

### Blocos dentro de Rotas (CAMINHOS):
Quando um bloco está DENTRO de uma rota de um bloco CAMINHOS, ele deve ter:
- `parentRouterId`: ID do bloco CAMINHOS pai
- `routeId`: ID da rota específica dentro do CAMINHOS
- `nextBlock`: Próximo bloco na sequência dessa rota

## FORMATO DE RESPOSTA

Retorne um JSON válido com esta estrutura:

```json
{
  "blocks": [
    {
      "block_key": "PM001",
      "block_type": "primeira_mensagem",
      "content": "Olá! Estou falando com [Nome do Lead]?",
      "next_block_key": "AG001",
      "order_index": 0,
      "parentRouterId": null,
      "routeId": null
    },
    {
      "block_key": "AG001",
      "block_type": "aguardar",
      "content": "Escute a resposta do lead",
      "variable_name": "ultima_resposta",
      "next_block_key": "CAM001",
      "order_index": 10,
      "parentRouterId": null,
      "routeId": null
    },
    {
      "block_key": "CAM001",
      "block_type": "caminhos",
      "content": "É a pessoa certa?",
      "analyze_variable": "{{ultima_resposta}}",
      "next_block_key": null,
      "order_index": 20,
      "parentRouterId": null,
      "routeId": null,
      "routes_data": [
        {
          "route_key": "CAM001_route_1",
          "label": "Confirmou que é ele",
          "keywords": ["sim", "sou eu", "isso", "pode falar"],
          "response": "Perfeito! Em que posso ajudar?",
          "destination_type": "continuar",
          "destination_block_key": "MSG001",
          "is_fallback": false,
          "ordem": 1,
          "cor": "#22c55e"
        },
        {
          "route_key": "CAM001_route_2",
          "label": "Não é a pessoa",
          "keywords": ["não", "engano", "número errado"],
          "response": "Desculpe pelo engano. Até logo!",
          "destination_type": "encerrar",
          "destination_block_key": "ENC001",
          "is_fallback": false,
          "ordem": 2,
          "cor": "#ef4444"
        },
        {
          "route_key": "CAM001_fallback",
          "label": "Não entendi",
          "keywords": [],
          "response": "Não entendi. Estou falando com [Nome do Lead]?",
          "destination_type": "loop",
          "destination_block_key": "AG001",
          "is_fallback": true,
          "ordem": 999,
          "cor": "#6b7280"
        }
      ]
    },
    {
      "block_key": "MSG001",
      "block_type": "mensagem",
      "content": "Ótimo! Vamos continuar...",
      "next_block_key": null,
      "order_index": 30,
      "parentRouterId": null,
      "routeId": null
    },
    {
      "block_key": "MSG002",
      "block_type": "mensagem",
      "content": "Esta mensagem está dentro da rota 1 do CAM001",
      "next_block_key": "MSG001",
      "order_index": 25,
      "parentRouterId": "CAM001",
      "routeId": "CAM001_route_1"
    }
  ]
}
```

## REGRAS IMPORTANTES

1. **Ordem dos blocos**: Use `order_index` para ordenar (0, 10, 20, 30... com espaçamento de 10)
2. **Blocos dentro de rotas**: Se um bloco aparece DEPOIS de uma rota específica no prompt, ele está DENTRO dessa rota
3. **next_block_key**: Sempre use o `block_key` (ex: "PM001"), não o ID UUID
4. **routes_data**: Apenas para blocos tipo "caminhos"
5. **parentRouterId e routeId**: Apenas para blocos que estão DENTRO de rotas
6. **Se um bloco não tem next_block_key explícito**: Analise o contexto para determinar o próximo bloco

## EXEMPLO DE ANÁLISE

Se o prompt tem:
```
### CAMINHOS [CAM001]
**Analisando:** `{{ultima_resposta}}`

**Se o lead disser:** "sim", "sou eu"
**Resposta:** "Perfeito!"
**Depois:** Va para [MSG002]

**Se o lead disser:** "não", "engano"
**Resposta:** "Desculpe!"
**Depois:** Va para [ENC001]

### MENSAGEM [MSG001]
**Fale:** "Esta mensagem está dentro da primeira rota"
**Depois:** Va para [MSG002]

### MENSAGEM [MSG002]
**Fale:** "Vamos continuar..."
```

Então:
- CAM001 tem duas rotas:
  - route_1: keywords ["sim", "sou eu"] → destino: MSG002
  - route_2: keywords ["não", "engano"] → destino: ENC001
- MSG001 está DENTRO da primeira rota porque:
  - Aparece DEPOIS da definição da rota 1
  - Aparece ANTES do destino final (MSG002)
  - Portanto: `parentRouterId: "CAM001"`, `routeId: "CAM001_route_1"`
- MSG002 está FORA da rota (parentRouterId: null) - é o destino final da primeira rota
- ENC001 está FORA da rota (parentRouterId: null) - é o destino da segunda rota

**REGRA CRÍTICA:** 
- Se um bloco aparece ENTRE uma rota específica e seu destino final → está DENTRO dessa rota
- Se um bloco É o destino final → está FORA da rota (parentRouterId: null)
- NUNCA coloque o mesmo bloco em múltiplas rotas (exceto se for destino final compartilhado)

## CONHECIMENTO AVANÇADO DO FLOW EDITOR

### ⚠️ REGRA CRÍTICA: Como Identificar Blocos Dentro de Rotas ESPECÍFICAS

**PROBLEMA COMUM:** Não misturar blocos entre rotas! Cada rota tem seus próprios blocos.

**MÉTODO PASSO A PASSO:**

1. **Identifique o bloco CAMINHOS** (ex: CAM001)
2. **Identifique TODAS as rotas** dentro do CAMINHOS (route_1, route_2, route_3, fallback)
3. **Para CADA rota, identifique:**
   - Onde a rota COMEÇA (keywords, label)
   - Onde a rota TERMINA (destination_block_key)
   - Quais blocos estão ENTRE o início e o fim da rota

**EXEMPLO DETALHADO:**

```
### CAMINHOS [CAM001]
**Analisando:** `{{ultima_resposta}}`

**Se o lead disser:** "sim", "sou eu"
**Resposta:** "Perfeito!"
**Depois:** Va para [MSG003]  ← ROTA 1 TERMINA AQUI

**Se o lead disser:** "não", "engano"
**Resposta:** "Desculpe!"
**Depois:** Va para [ENC001]  ← ROTA 2 TERMINA AQUI

### MENSAGEM [MSG001]
**Fale:** "Esta mensagem está na rota 1"
**Depois:** Va para [MSG002]

### MENSAGEM [MSG002]
**Fale:** "Continuando rota 1"
**Depois:** Va para [MSG003]

### MENSAGEM [MSG003]
**Fale:** "Destino final da rota 1"

### ENCERRAR [ENC001]
**Fale:** "Encerrando"
```

**ANÁLISE CORRETA:**
- CAM001 tem 2 rotas:
  - Rota 1: keywords ["sim", "sou eu"] → destino: MSG003
  - Rota 2: keywords ["não", "engano"] → destino: ENC001
- MSG001 está ENTRE rota 1 e MSG003 → `parentRouterId: "CAM001"`, `routeId: "CAM001_route_1"`
- MSG002 está ENTRE rota 1 e MSG003 → `parentRouterId: "CAM001"`, `routeId: "CAM001_route_1"`
- MSG003 é o DESTINO FINAL da rota 1 → `parentRouterId: null` (FORA da rota)
- ENC001 é o DESTINO FINAL da rota 2 → `parentRouterId: null` (FORA da rota)

**❌ ERRADO:** Colocar MSG001 ou MSG002 na rota 2 ou no meio
**✅ CERTO:** MSG001 e MSG002 estão APENAS na rota 1

### REGRAS DE IDENTIFICAÇÃO:

1. **Cada rota tem um destino final** (`destination_block_key`)
2. **Blocos que aparecem ANTES do destino final e DEPOIS da definição da rota** estão DENTRO dessa rota
3. **Blocos que são o destino final** estão FORA da rota (`parentRouterId: null`)
4. **NUNCA coloque o mesmo bloco em múltiplas rotas** (exceto se for destino final)
5. **Siga a ordem do prompt** - se MSG001 aparece depois da rota 1 e antes de MSG003, está na rota 1

### EXEMPLO COM MÚLTIPLAS ROTAS:

```
### CAMINHOS [CAM001]
**Se o lead disser:** "sim" → Va para [MSG005]  ← ROTA 1
**Se o lead disser:** "não" → Va para [MSG006]  ← ROTA 2
**Se o lead disser:** "talvez" → Va para [MSG007]  ← ROTA 3

### MENSAGEM [MSG001]
**Fale:** "Mensagem da rota 1"
**Depois:** Va para [MSG002]

### MENSAGEM [MSG002]
**Fale:** "Continuando rota 1"
**Depois:** Va para [MSG005]

### MENSAGEM [MSG003]
**Fale:** "Mensagem da rota 2"
**Depois:** Va para [MSG004]

### MENSAGEM [MSG004]
**Fale:** "Continuando rota 2"
**Depois:** Va para [MSG006]

### MENSAGEM [MSG005]  ← Destino final rota 1
**Fale:** "Fim rota 1"

### MENSAGEM [MSG006]  ← Destino final rota 2
**Fale:** "Fim rota 2"

### MENSAGEM [MSG007]  ← Destino final rota 3
**Fale:** "Fim rota 3"
```

**ANÁLISE:**
- MSG001 e MSG002: `parentRouterId: "CAM001"`, `routeId: "CAM001_route_1"` (rota 1)
- MSG003 e MSG004: `parentRouterId: "CAM001"`, `routeId: "CAM001_route_2"` (rota 2)
- MSG005: `parentRouterId: null` (destino final rota 1)
- MSG006: `parentRouterId: null` (destino final rota 2)
- MSG007: `parentRouterId: null` (destino final rota 3)

### Cores Padrão para Rotas:
- Verde (#22c55e) - Respostas positivas/afirmativas
- Vermelho (#ef4444) - Respostas negativas
- Azul (#3b82f6) - Respostas neutras/informativas
- Amarelo (#eab308) - Avisos/atenção
- Roxo (#a855f7) - Alternativas
- Cinza (#6b7280) - Fallback (sempre)

### Destination Types:
- `"continuar"` - Continua para próximo bloco (usa destination_block_key)
- `"encerrar"` - Encerra a conversa
- `"loop"` - Volta para bloco anterior (geralmente fallback)

### Variáveis Comuns:
- `{{ultima_resposta}}` - Resposta mais recente do lead
- `{{nome_lead}}` - Nome do lead
- `{{email_lead}}` - Email do lead
- Variáveis são sempre entre `{{}}`

### Ordem de Blocos (order_index):
- Use espaçamento de 10: 0, 10, 20, 30, 40...
- Blocos dentro de rotas: Use ordem intermediária (ex: 25 entre 20 e 30)
- Sempre comece com 0 para primeira_mensagem

### Block Keys (Identificadores):
- PM001, PM002... - Primeira mensagem
- AG001, AG002... - Aguardar
- CAM001, CAM002... - Caminhos
- MSG001, MSG002... - Mensagem
- ENC001, ENC002... - Encerrar
- TOOL001, TOOL002... - Ferramenta

## REGRAS FINAIS - CRÍTICAS PARA EVITAR ERROS

1. **SEMPRE extrair TODOS os blocos**, mesmo os que estão dentro de rotas
2. **SEMPRE criar routes_data completo** para blocos tipo "caminhos"
3. **SEMPRE identificar parentRouterId e routeId CORRETAMENTE** para blocos dentro de rotas
4. **NUNCA misturar blocos entre rotas** - cada rota tem seus próprios blocos
5. **SEMPRE seguir a ordem lógica** do fluxo no prompt
6. **Para cada rota, identifique:**
   - Onde começa (keywords/label)
   - Onde termina (destination_block_key)
   - Quais blocos estão entre início e fim
7. **Blocos que são destino final** sempre têm `parentRouterId: null`
8. **Se não tem next_block_key explícito**, analise o contexto para determinar

## PROCESSO DE ANÁLISE RECOMENDADO (SEQUENCIAL) - ⚠️ CRÍTICO

**⚠️ IMPORTANTE:** Analise o prompt de forma SEQUENCIAL, linha por linha, seguindo a ordem de aparecimento. **CADA ROTA TEM SUA PRÓPRIA SEQUÊNCIA DE BLOCOS - NÃO MISTURE!**

### Passo 1: Identificar Blocos CAMINHOS
- Procure por `### CAMINHOS [CAM001]` ou similar
- Para cada CAMINHOS encontrado, extraia todas as rotas
- Anote o `destination_block_key` de cada rota (onde a rota TERMINA)

### Passo 2: Para Cada Rota, Seguir a CADEIA DE next_block_key SEPARADAMENTE

**⚠️ REGRA CRÍTICA:** Cada rota tem sua própria cadeia de blocos. Siga cada cadeia separadamente!

**Algoritmo para cada rota:**
1. Pegue o `destination_block_key` da rota (ex: rota 1 vai para MSG003)
2. Comece a partir desse bloco e SIGA a cadeia de `next_block_key`:
   - MSG003 tem `next_block_key: MSG004`? → MSG004 está na mesma rota
   - MSG004 tem `next_block_key: MSG005`? → MSG005 está na mesma rota
   - Continue até encontrar um bloco sem `next_block_key` ou que aponte para fora da rota
3. **TODOS os blocos nessa cadeia pertencem a essa rota**
4. O último bloco da cadeia (sem next_block_key) é o destino final → `parentRouterId: null`

### Passo 3: NUNCA Misturar Blocos Entre Rotas

**❌ ERRADO:**
- Colocar MSG001 na rota 1 E na rota 2
- Colocar blocos da rota 1 na rota 2

**✅ CERTO:**
- Rota 1: MSG001 → MSG002 → MSG003 (todos com `routeId: "CAM001_route_1"`)
- Rota 2: MSG004 → MSG005 → MSG006 (todos com `routeId: "CAM001_route_2"`)
- Cada rota tem seus próprios blocos, sem mistura

### Passo 4: Mapear Blocos para Rotas Corretamente

Para cada bloco encontrado:
1. Verifique se ele está na cadeia de alguma rota (seguindo next_block_key)
2. Se está na cadeia da rota 1 → `parentRouterId: "CAM001"`, `routeId: "CAM001_route_1"`
3. Se está na cadeia da rota 2 → `parentRouterId: "CAM001"`, `routeId: "CAM001_route_2"`
4. Se não está em nenhuma cadeia → `parentRouterId: null` (bloco independente)
5. Se é o destino final de uma rota → `parentRouterId: null` (termina a rota)

### Exemplo Prático de Análise Sequencial - SEGUINDO CADA ROTA SEPARADAMENTE:

```
### CAMINHOS [CAM001]
**Se o lead disser:** "sim" → Va para [MSG001]  ← ROTA 1: começa em MSG001
**Se o lead disser:** "não" → Va para [MSG004]  ← ROTA 2: começa em MSG004

### MENSAGEM [MSG001]  ← PRIMEIRO BLOCO DA ROTA 1
**Fale:** "Mensagem 1 da rota 1"
**Depois:** Va para [MSG002]

### MENSAGEM [MSG002]  ← SEGUNDO BLOCO DA ROTA 1 (segue cadeia de MSG001)
**Fale:** "Mensagem 2 da rota 1"
**Depois:** Va para [MSG003]

### MENSAGEM [MSG003]  ← TERCEIRO BLOCO DA ROTA 1 (segue cadeia de MSG002)
**Fale:** "Fim da rota 1"
**Depois:** (sem next_block_key - destino final)

### MENSAGEM [MSG004]  ← PRIMEIRO BLOCO DA ROTA 2
**Fale:** "Mensagem 1 da rota 2"
**Depois:** Va para [MSG005]

### MENSAGEM [MSG005]  ← SEGUNDO BLOCO DA ROTA 2 (segue cadeia de MSG004)
**Fale:** "Fim da rota 2"
**Depois:** (sem next_block_key - destino final)
```

**Análise CORRETA seguindo cadeias separadas:**

**ROTA 1 (CAM001_route_1):**
- Cadeia: MSG001 → MSG002 → MSG003
- MSG001: `parentRouterId: "CAM001"`, `routeId: "CAM001_route_1"`, `next_block_key: "MSG002"`
- MSG002: `parentRouterId: "CAM001"`, `routeId: "CAM001_route_1"`, `next_block_key: "MSG003"`
- MSG003: `parentRouterId: null` (destino final da rota 1), `next_block_key: null`

**ROTA 2 (CAM001_route_2):**
- Cadeia: MSG004 → MSG005
- MSG004: `parentRouterId: "CAM001"`, `routeId: "CAM001_route_2"`, `next_block_key: "MSG005"`
- MSG005: `parentRouterId: null` (destino final da rota 2), `next_block_key: null`

**⚠️ NUNCA colocar MSG001, MSG002 ou MSG003 na rota 2!**
**⚠️ NUNCA colocar MSG004 ou MSG005 na rota 1!**

### Passo 5: Verificação Final - ⚠️ CRÍTICO

Antes de retornar o JSON, verifique:

1. **Cada rota tem seus próprios blocos** - nenhum bloco está em múltiplas rotas
2. **Cadeias de next_block_key estão corretas** - cada rota forma uma cadeia contínua
3. **Destinos finais estão corretos** - blocos sem next_block_key ou que terminam a rota têm `parentRouterId: null`
4. **Blocos independentes** - blocos que não pertencem a nenhuma rota têm `parentRouterId: null`

**Exemplo de verificação:**
- ✅ Rota 1: MSG001 → MSG002 → MSG003 (todos com mesmo routeId)
- ✅ Rota 2: MSG004 → MSG005 (todos com mesmo routeId, diferente da rota 1)
- ❌ ERRADO: MSG001 na rota 1 E na rota 2
- ❌ ERRADO: MSG003 na rota 1 mas MSG004 também na rota 1 (MSG004 pertence à rota 2!)

Retorne APENAS o JSON válido, sem markdown, sem explicações adicionais."""

    def analyze_prompt_to_blocks(self, prompt: str) -> List[Dict[str, Any]]:
        """
        Analisa o prompt completo e retorna lista de blocos estruturados
        
        Args:
            prompt: Prompt completo do assistente (formato Markdown)
            
        Returns:
            Lista de blocos com estrutura completa, incluindo blocos dentro de rotas
        """
        if not prompt or not prompt.strip():
            logger.warning("analyze_prompt_to_blocks: Prompt vazio")
            return []
        
        system_prompt = self._build_system_prompt()
        
        try:
            if self.provider == "anthropic":
                message = self.client.messages.create(
                    model=self.model,
                    max_tokens=4096,
                    system=system_prompt,
                    messages=[
                        {
                            "role": "user",
                            "content": f"""Analise este prompt completo e extraia TODOS os blocos, incluindo blocos que estão DENTRO de rotas:

{prompt}

Retorne APENAS o JSON válido com a estrutura de blocos especificada."""
                        }
                    ]
                )
                response_text = message.content[0].text
            else:  # OpenAI
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {
                            "role": "user",
                            "content": f"""Analise este prompt completo e extraia TODOS os blocos, incluindo blocos que estão DENTRO de rotas:

{prompt}

Retorne APENAS o JSON válido com a estrutura de blocos especificada."""
                        }
                    ],
                    temperature=0.1,
                    max_tokens=4096
                )
                response_text = response.choices[0].message.content
            
            # Extrair JSON da resposta (pode ter markdown code blocks)
            json_text = response_text.strip()
            if json_text.startswith("```json"):
                json_text = json_text[7:]
            if json_text.startswith("```"):
                json_text = json_text[3:]
            if json_text.endswith("```"):
                json_text = json_text[:-3]
            json_text = json_text.strip()
            
            # Parse JSON
            result = json.loads(json_text)
            blocks = result.get("blocks", [])
            
            logger.info(f"✅ [FlowAIAnalyzer] IA analisou prompt e encontrou {len(blocks)} blocos")
            
            # Log detalhado
            for block in blocks:
                block_key = block.get("block_key", "SEM_KEY")
                block_type = block.get("block_type", "SEM_TIPO")
                parent_router = block.get("parentRouterId")
                route_id = block.get("routeId")
                
                if parent_router:
                    logger.info(f"  📍 Bloco {block_key} ({block_type}) está DENTRO da rota {route_id} do bloco {parent_router}")
                else:
                    logger.info(f"  📍 Bloco {block_key} ({block_type}) está na sequência principal")
            
            return blocks
            
        except json.JSONDecodeError as e:
            logger.error(f"❌ [FlowAIAnalyzer] Erro ao fazer parse do JSON retornado pela IA: {e}")
            logger.error(f"Resposta da IA: {response_text[:500]}")
            return []
        except Exception as e:
            logger.error(f"❌ [FlowAIAnalyzer] Erro ao analisar prompt com IA: {e}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
            return []


def analyze_prompt_with_ai(prompt: str, provider: str = "openai") -> List[Dict[str, Any]]:
    """
    Função helper para analisar prompt usando IA
    
    Args:
        prompt: Prompt completo do assistente
        provider: "anthropic" (Claude) ou "openai" (GPT)
        
    Returns:
        Lista de blocos estruturados
    """
    analyzer = FlowAIAnalyzer(provider=provider)
    return analyzer.analyze_prompt_to_blocks(prompt)
