"""
Monta o prompt final a partir de flow + flow_blocks + flow_routes.
Usado pela IA de voz (VAPI) ao iniciar ligação.
"""
from typing import Dict, Any, List, Optional

from saas_tools.services import flow_service


def build_prompt_from_flow(
    flow: Dict[str, Any],
    blocks: List[Dict[str, Any]],
    routes: List[Dict[str, Any]],
) -> str:
    """
    Monta o texto final do prompt a partir dos dados do banco.
    Cabeçalho + prompt_base + seção FLUXO DA CONVERSA com blocos ordenados.
    """
    prompt = ""

    # PARTE 1: Cabeçalho e Prompt Base
    name = (flow.get("name") or "Flow").upper()
    prompt += f"# PROMPT - {name}\n\n"

    prompt_base = flow.get("prompt_base") or ""
    if prompt_base:
        prompt += prompt_base
        prompt += "\n\n---\n\n"

    # PARTE 2: Fluxo da Conversa
    prompt += "## FLUXO DA CONVERSA\n\n"

    routes_by_block_id: Dict[str, List[Dict[str, Any]]] = {}
    for route in routes:
        bid = route.get("block_id")
        if bid:
            bid_str = str(bid)
            if bid_str not in routes_by_block_id:
                routes_by_block_id[bid_str] = []
            routes_by_block_id[bid_str].append(route)

    sorted_blocks = sorted(blocks, key=lambda b: b.get("order_index") or 0)

    for block in sorted_blocks:
        block_id = block.get("id")
        block_routes = routes_by_block_id.get(str(block_id), []) if block_id else []
        prompt += _format_block(block, block_routes)
        prompt += "\n---\n\n"

    return prompt


def _format_block(block: Dict[str, Any], routes: List[Dict[str, Any]]) -> str:
    """Formata um bloco individual para o prompt."""
    output = ""
    block_type = block.get("block_type") or ""
    content = (block.get("content") or "").replace('"', '\\"')
    block_key = block.get("block_key") or ""
    next_block_key = block.get("next_block_key")

    if block_type == "primeira_mensagem":
        output += "### ABERTURA DA LIGACAO\n\n"
        output += "**Ao iniciar a ligacao, fale:**\n\n"
        output += f'"{block.get("content", "")}"\n\n'
        if next_block_key:
            output += f"**Depois:** Va para [{next_block_key}]\n"

    elif block_type == "mensagem":
        output += f"### MENSAGEM [{block_key}]\n\n"
        output += "**Fale:**\n\n"
        output += f'"{block.get("content", "")}"\n\n'
        if next_block_key:
            output += f"**Depois:** Va para [{next_block_key}]\n"

    elif block_type == "aguardar":
        output += f"### AGUARDAR [{block_key}]\n\n"
        output += f"**{block.get('content', '')}**\n\n"
        var = block.get("variable_name")
        if var:
            output += f"Salvar resposta do lead em: `{{{{{var}}}}}`\n\n"
        if next_block_key:
            output += f"**Depois:** Va para [{next_block_key}]\n"

    elif block_type == "caminhos":
        output += f"### CAMINHOS [{block_key}]\n\n"
        analyze = block.get("analyze_variable") or "{{ultima_resposta}}"
        output += f"**Analisando:** `{analyze}`\n\n"
        output += f"**{block.get('content', '')}**\n\n"
        sorted_routes = sorted(
            routes,
            key=lambda r: (1 if r.get("is_fallback") else 0, r.get("ordem") or 0),
        )
        for route in sorted_routes:
            output += _format_route(route)

    elif block_type == "ferramenta":
        output += f"### FERRAMENTA [{block_key}]: {block.get('tool_type', '')}\n\n"
        output += f"**{block.get('content', '')}**\n\n"
        tool_config = block.get("tool_config") or {}
        if isinstance(tool_config, dict) and tool_config:
            import json
            output += f"Configuracao: {json.dumps(tool_config)}\n\n"
        if next_block_key:
            output += f"**Depois:** Va para [{next_block_key}]\n"

    elif block_type == "encerrar":
        output += f"### ENCERRAR [{block_key}]: {block.get('end_type', '')}\n\n"
        output += "**Fale antes de encerrar:**\n\n"
        output += f'"{block.get("content", "")}"\n\n'
        end_meta = block.get("end_metadata") or {}
        if isinstance(end_meta, dict) and end_meta:
            import json
            output += f"Acao: {block.get('end_type', '')}\n"
            output += f"Metadata: {json.dumps(end_meta)}\n"

    return output


def _format_route(route: Dict[str, Any]) -> str:
    """Formata uma rota individual."""
    output = ""
    is_fallback = route.get("is_fallback") or False
    cor = route.get("cor") or "#6b7280"
    emoji = "?" if is_fallback else "->"
    if cor == "#22c55e":
        emoji = "+"
    elif cor == "#ef4444":
        emoji = "x"
    label = route.get("label") or route.get("route_key") or ""
    output += f"#### {emoji} {label}\n\n"

    keywords = route.get("keywords") or []
    if isinstance(keywords, str):
        keywords = [keywords] if keywords else []
    if keywords:
        output += f"**Quando o lead disser:** `{'`, `'.join(keywords)}`\n\n"
    elif is_fallback:
        output += "**Quando nenhuma condicao acima for atendida**\n\n"

    response = route.get("response")
    if response:
        output += f'**Fale:**\n"{response}"\n\n'

    dest_type = route.get("destination_type") or "continuar"
    dest_key = route.get("destination_block_key") or ""
    if dest_type == "continuar":
        output += f"**Depois:** Continue para [{dest_key}]\n\n"
    elif dest_type == "goto":
        output += f"**Depois:** Va para [{dest_key}]\n\n"
    elif dest_type == "loop":
        max_loop = route.get("max_loop_attempts") or 2
        output += f"**Depois:** Volte para [{dest_key}] (maximo {max_loop} tentativas)\n\n"
    elif dest_type == "encerrar":
        output += f"**Depois:** Encerre em [{dest_key}]\n\n"

    return output


def get_prompt_for_flow(flow_id: str) -> Optional[str]:
    """
    Busca o flow completo e monta o prompt.
    Retorna o texto para uso na IA de voz (VAPI) ou None se flow não existir.
    """
    data = flow_service.get_flow_complete(flow_id)
    if not data or not data.get("flow"):
        return None
    flow = data["flow"]
    blocks = data.get("blocks") or []
    routes = data.get("routes") or []
    return build_prompt_from_flow(flow, blocks, routes)
