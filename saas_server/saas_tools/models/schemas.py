from pydantic import BaseModel
from typing import Optional, Any, Dict, List
from enum import Enum


class ToolType(str, Enum):
    """Tipos de tool disponíveis"""

    MENSAGEM = "mensagem"
    ENCERRAMENTO = "encerramento"
    DOCUMENTO = "documento"


class FileType(str, Enum):
    """Tipos de arquivo/conteúdo"""

    TEXTO = "texto"
    AUDIO = "audio"
    ARQUIVO = "arquivo"
    IMAGEM = "imagem"
    VIDEO = "video"
    PDF = "pdf"
    DOC = "doc"
    DOCX = "docx"
    TXT = "txt"


class ToolCreate(BaseModel):
    tenant_id: str
    tool_name: str
    tool_type: ToolType
    file_type: Optional[FileType] = None
    is_active: bool = True
    instancia: Optional[str] = None
    mensagem: Optional[str] = None
    file_url: Optional[str] = None
    prompt_instructions: str
    assistant_id: Optional[str] = None


class ToolUpdate(BaseModel):
    tool_name: Optional[str] = None
    tool_type: Optional[ToolType] = None
    file_type: Optional[FileType] = None
    is_active: Optional[bool] = None
    instancia: Optional[str] = None
    mensagem: Optional[str] = None
    file_url: Optional[str] = None
    prompt_instructions: Optional[str] = None


# ============================================================================
# Assistants (profiles / flows)
# ============================================================================
class AssistantProfileUpsert(BaseModel):
    identity: str = ""
    personality: str = ""
    phonetic_rules: str = ""
    absolute_rules: str = ""
    natural_expressions: str = ""
    scheduling_rules: Dict[str, Any] = {}


class AssistantFlowUpsert(BaseModel):
    flow_json: Dict[str, Any]
    title: str = ""
    description: str = ""


class PromptImportParseRequest(BaseModel):
    prompt_master: str


class PromptImportParseResponse(BaseModel):
    extracted_globals: Dict[str, Any]
    suggested_blocks: List[Dict[str, Any]]


# ============================================================================
# Flow Editor (flows, flow_blocks, flow_routes)
# ============================================================================

FlowBlockType = str  # 'primeira_mensagem' | 'mensagem' | 'aguardar' | 'caminhos' | 'ferramenta' | 'encerrar'
ToolTypeFlow = str   # 'buscar_dados' | 'verificar_agenda' | 'agendar' | 'enviar_whatsapp' | 'consultar_documento' | 'webhook'
EndTypeFlow = str    # 'transferir' | 'finalizar' | 'nao_qualificado' | 'agendar_retorno'
DestinationTypeFlow = str  # 'continuar' | 'goto' | 'loop' | 'encerrar'


class FlowBlockUpsert(BaseModel):
    """Bloco para salvar (frontend envia block_key, não id do banco)."""
    block_key: str
    block_type: str
    content: str = ""
    variable_name: Optional[str] = None
    timeout_seconds: Optional[int] = None
    analyze_variable: Optional[str] = None
    tool_type: Optional[str] = None
    tool_config: Dict[str, Any] = {}
    end_type: Optional[str] = None
    end_metadata: Dict[str, Any] = {}
    next_block_key: Optional[str] = None
    order_index: int = 0
    position_x: float = 0
    position_y: float = 0
    routes: Optional[List["FlowRouteUpsert"]] = None  # ⚠️ DEPRECATED: Usar routes_data
    routes_data: Optional[List[Dict[str, Any]]] = None  # ⭐ NOVO: JSONB array com routes (para blocos tipo "caminhos")


class FlowRouteUpsert(BaseModel):
    """Rota para salvar; referência ao bloco pai por block_key (não block_id)."""
    block_key: str  # bloco pai (tipo caminhos)
    route_key: str
    label: str = ""
    ordem: int = 0
    cor: str = "#6b7280"
    keywords: List[str] = []
    response: Optional[str] = None
    destination_type: str = "continuar"
    destination_block_key: Optional[str] = None
    max_loop_attempts: int = 2
    is_fallback: bool = False


class SaveFlowPayload(BaseModel):
    flow_id: str
    blocks: List[FlowBlockUpsert]
    routes: List[FlowRouteUpsert]


class SaveFlowResult(BaseModel):
    success: bool
    version: int = 0
    error: Optional[str] = None


class FlowCreate(BaseModel):
    tenant_id: str
    name: str
    assistente_id: Optional[str] = None
    prompt_base: Optional[str] = None
    description: Optional[str] = None


class FlowUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    prompt_base: Optional[str] = None
    status: Optional[str] = None
    is_active: Optional[bool] = None


BLOCK_KEY_PREFIXES = {
    "primeira_mensagem": "PM",
    "mensagem": "MSG",
    "aguardar": "AG",
    "caminhos": "CAM",
    "ferramenta": "FER",
    "encerrar": "ENC",
}


# ============================================================================
# AI Prompt Patcher
# ============================================================================

class AIPatchPromptRequest(BaseModel):
    """Request para fazer patch cirúrgico de prompt usando IA"""
    assistente_id: str
    block_key: str
    block_type: str
    new_content: str
    next_block_key: Optional[str] = None
    variable_name: Optional[str] = None
    provider: str = "anthropic"  # "anthropic" ou "openai"


class AIPatchPromptResponse(BaseModel):
    """Response do patch com IA"""
    success: bool
    updated_prompt: Optional[str] = None
    error: Optional[str] = None
    prompt_length_before: Optional[int] = None
    prompt_length_after: Optional[int] = None
