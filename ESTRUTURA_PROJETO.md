# ESTRUTURA COMPLETA DO PROJETO SAAS

## DIRETÓRIOS PRINCIPAIS

### `/saas_server/`
Servidor backend completo (Python/FastAPI)

**Estrutura:**
```
saas_server/
├── saas_tools/
│   ├── api/                    # Endpoints REST
│   │   ├── flows.py           # Flow Editor API
│   │   ├── assistants.py      # Assistentes API
│   │   ├── tools.py           # Tools API
│   │   └── dashboard.py       # Dashboard API
│   ├── services/              # Lógica de negócio
│   │   ├── flow_service.py    # Serviço de flows
│   │   ├── flow_ai_analyzer.py # Análise com IA
│   │   ├── prompt_parser.py   # Parser de prompts
│   │   ├── prompt_builder.py  # Builder de prompts
│   │   ├── supabase_service.py # Conexão Supabase
│   │   └── file_service.py    # Serviço de arquivos
│   ├── models/
│   │   └── schemas.py         # Schemas Pydantic
│   └── config.py              # Configurações
├── supabase/                  # Scripts SQL
│   ├── migrations/            # Migrations
│   └── triggers/              # Triggers
├── docs/                      # Documentação
├── main.py                    # Ponto de entrada
├── .env                       # Variáveis de ambiente
└── requirements.txt           # Dependências Python
```

### `/menu_principal/`
Frontend HTML/JS do sistema antigo

**Estrutura:**
```
menu_principal/
├── assistentes/
│   ├── assistente.html        # Página principal de assistentes
│   ├── assistente-editor.html # Editor de assistentes
│   ├── importador-prompt.html # Importador de prompts
│   └── tools/                 # Páginas de tools
│       ├── gerenciar-tools.html
│       └── static/js/tools.js
├── campanhas/                 # Páginas de campanhas
└── outros módulos...
```

### Arquivos raiz
- `README.md` - Documentação principal
- `PLANO_IMPLEMENTACAO_PROMPT_CANONICO.md` - Plano de implementação
- `*.md` - Outros arquivos de documentação
- `*.sh` - Scripts de inicialização
- `*.html` - Páginas HTML principais

## COMPONENTES DO SISTEMA

### 1. Flow Editor
**Frontend**: React/TypeScript (em `assist-tool-craft-main 2/`)
**Backend**: `saas_server/saas_tools/api/flows.py`
**Banco**: Tabela `flow_blocks` no Supabase

### 2. Assistentes
**API**: `saas_server/saas_tools/api/assistants.py`
**Frontend HTML**: `menu_principal/assistentes/`

### 3. Tools
**API**: `saas_server/saas_tools/api/tools.py`
**Frontend HTML**: `menu_principal/assistentes/tools/`

### 4. Dashboard
**API**: `saas_server/saas_tools/api/dashboard.py`

## BANCO DE DADOS (Supabase)

### Tabelas principais:
- `flows` - Fluxos de conversa
- `flow_blocks` - Blocos do flow (com routes_data JSONB)
- `assistentes` - Assistentes de voz
- `vapi_tools` - Ferramentas disponíveis
- `campanhas` - Campanhas de marketing

## COMO INICIAR

### Backend:
```bash
cd saas_server
source .venv/bin/activate  # ou criar novo venv
pip install -r requirements.txt
uvicorn main:app --port 8081
```

### Frontend Flow Editor:
```bash
cd assist-tool-craft-main\ 2
npm install
npm run dev
```

### Frontend HTML:
Servir `menu_principal/` via servidor web (ex: Python http.server)

## VARIÁVEIS DE AMBIENTE

Criar `.env` em `saas_server/`:
```
SUPABASE_URL=...
SUPABASE_KEY=...
OPENAI_API_KEY=...
ANTHROPIC_API_KEY=...
```

## ARQUIVOS IMPORTANTES

### Backend:
- `saas_server/main.py` - Servidor FastAPI
- `saas_server/saas_tools/api/flows.py` - API Flow Editor
- `saas_server/saas_tools/services/flow_service.py` - Lógica de flows
- `saas_server/saas_tools/models/schemas.py` - Validação de dados

### Frontend HTML:
- `menu_principal/assistentes/assistente.html` - Página principal
- `menu_principal/assistentes/tools/static/js/tools.js` - JS de tools

### Scripts:
- `iniciar_porta_8081.sh` - Iniciar servidor na porta 8081
- `verificar_sistema_completo.sh` - Verificar sistema

## DOCUMENTAÇÃO

Ver arquivos `.md` na raiz para documentação específica de cada módulo.
