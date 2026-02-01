from fastapi import APIRouter, HTTPException
from typing import Any, Dict, List, Tuple
import logging
import re

from saas_tools.models.schemas import (
    AssistantProfileUpsert,
    AssistantFlowUpsert,
    PromptImportParseRequest,
)
from saas_tools.services.supabase_service import supabase_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["assistants"])


def _normalize_heading(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip()).upper()


def _split_markdown_sections(text: str) -> List[Tuple[str, str]]:
    """
    Split by markdown headings (#/##/###). Returns list of (heading, body).
    If no headings exist, returns single ("", text).
    """
    lines = text.splitlines()
    sections: List[Tuple[str, List[str]]] = []
    current_heading = ""
    current_body: List[str] = []

    heading_re = re.compile(r"^\s{0,3}(#{1,6})\s+(.*\S)\s*$")

    for line in lines:
        m = heading_re.match(line)
        if m:
            # flush previous
            if current_heading or current_body:
                sections.append((current_heading, current_body))
            current_heading = m.group(2).strip()
            current_body = []
        else:
            current_body.append(line)

    if current_heading or current_body:
        sections.append((current_heading, current_body))

    if not sections:
        return [("", text)]

    return [(h, "\n".join(b).strip()) for (h, b) in sections]


def parse_prompt_master(prompt_master: str) -> Dict[str, Any]:
    """
    Very lightweight heuristic parser.
    - Extracts global sections (identity/personality/phonetic/absolute/natural/scheduling)
    - Suggests a basic blocks list based on lines containing markers like:
      "ABERTURA", "PASSO", "AGUARDE", "AGUARDE RESPOSTA", "ENCERRAR", "CHAME TOOL"
    """
    sections = _split_markdown_sections(prompt_master)

    extracted: Dict[str, Any] = {
        "identity": "",
        "personality": "",
        "phonetic_rules": "",
        "absolute_rules": "",
        "natural_expressions": "",
        "scheduling_rules": {},
    }

    # Map common Portuguese headings to profile fields
    for heading, body in sections:
        h = _normalize_heading(heading)
        if not body:
            continue

        if any(k in h for k in ["IDENTIDADE", "PAPEL DA IA", "QUEM VOCÊ É", "SOBRE A IA"]):
            extracted["identity"] = body
        elif any(k in h for k in ["PERSONALIDADE", "TOM", "DIRETRIZES DE EXECUÇÃO", "DIRETRIZES"]):
            # keep existing if already set; otherwise set
            extracted["personality"] = extracted["personality"] or body
        elif any(k in h for k in ["PRONÚNCIA", "PRONUNCIA", "FONÉTICA", "FONETICA"]):
            extracted["phonetic_rules"] = body
        elif any(k in h for k in ["REGRAS ABSOLUTAS", "PROIBIÇÕES", "PROIBICOES", "NÃO NEGOCIÁVEIS", "NAO NEGOCIAVEIS"]):
            extracted["absolute_rules"] = body
        elif any(k in h for k in ["EXPRESSÕES", "EXPRESSOES", "CONECTIVOS"]):
            extracted["natural_expressions"] = body
        elif any(k in h for k in ["AGENDAMENTO", "AGENDA", "JANELA", "DIAS ÚTEIS", "DIAS UTEIS"]):
            # Try to keep raw in scheduling_rules.raw if unknown format
            extracted["scheduling_rules"] = {"raw": body}

    # Suggest blocks: scan lines for quoted scripts and markers
    suggested_blocks: List[Dict[str, Any]] = []
    lines = [ln.strip() for ln in prompt_master.splitlines() if ln.strip()]

    def push_text(msg: str):
        suggested_blocks.append(
            {
                "type": "texto",
                "content": msg.strip(),
            }
        )

    def push_first(msg: str):
        suggested_blocks.append(
            {
                "type": "primeira_mensagem",
                "content": msg.strip(),
            }
        )

    def push_wait(label: str = "Aguardar resposta", timeout: int = 30):
        suggested_blocks.append(
            {
                "type": "aguardar",
                "content": label,
                "timeout": timeout,
            }
        )

    def push_end(label: str = "Encerrar conversa"):
        suggested_blocks.append(
            {
                "type": "encerrar",
                "content": label,
            }
        )

    def push_tool(tool_name: str):
        # We do not know the toolType mapping here; leave placeholder
        suggested_blocks.append(
            {
                "type": "tool",
                "content": tool_name.strip(),
                "toolType": "salvar_dados",
            }
        )

    # Extract lines in quotes as "script" messages
    quote_re = re.compile(r'["“](.+?)["”]\s*$')
    first_message_set = False

    for ln in lines:
        up = ln.upper()

        if "AGUARDE" in up:
            push_wait("Aguardar resposta", 30)
            continue
        if "ENCERRAR" in up and "NÃO" not in up and "NAO" not in up:
            push_end()
            continue
        if "CHAME" in up and "TOOL" in up:
            # naive: CHAME tool X
            m = re.search(r"CHAME\s+TOOL\s+(.+)$", ln, re.IGNORECASE)
            push_tool(m.group(1) if m else "Chamar tool")
            continue

        m = quote_re.search(ln)
        if m:
            msg = m.group(1).strip()
            if msg:
                if not first_message_set:
                    push_first(msg)
                    first_message_set = True
                else:
                    push_text(msg)
            continue

    return {"extracted_globals": extracted, "suggested_blocks": suggested_blocks}


@router.get("/assistants/{assistant_id}/profile")
async def get_profile(assistant_id: str):
    try:
        profile = supabase_service.get_assistant_profile(assistant_id)
        if not profile:
            return {"success": True, "profile": {"assistant_id": assistant_id}}
        return {"success": True, "profile": profile}
    except Exception as e:
        logger.error(f"Erro ao buscar assistant_profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/assistants/{assistant_id}/profile")
async def upsert_profile(assistant_id: str, payload: AssistantProfileUpsert):
    try:
        saved = supabase_service.upsert_assistant_profile(assistant_id, payload.model_dump())
        return {"success": True, "profile": saved}
    except Exception as e:
        logger.error(f"Erro ao salvar assistant_profile: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/assistants/{assistant_id}/flow")
async def get_flow(assistant_id: str):
    try:
        flow = supabase_service.get_assistant_flow(assistant_id)
        if not flow:
            return {"success": True, "flow": None}
        return {"success": True, "flow": flow}
    except Exception as e:
        logger.error(f"Erro ao buscar assistant_flow: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/assistants/{assistant_id}/flow")
async def upsert_flow(assistant_id: str, payload: AssistantFlowUpsert):
    try:
        saved = supabase_service.upsert_assistant_flow(
            assistant_id,
            payload.flow_json,
            meta={"title": payload.title, "description": payload.description},
        )
        return {"success": True, "flow": saved}
    except Exception as e:
        logger.error(f"Erro ao salvar assistant_flow: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/assistants/{assistant_id}/prompt-import/parse")
async def prompt_import_parse(assistant_id: str, req: PromptImportParseRequest):
    try:
        parsed = parse_prompt_master(req.prompt_master)
        # optional: store history (best-effort)
        try:
            supabase_service.create_prompt_import_run(
                assistant_id,
                {
                    "input_text": req.prompt_master,
                    "extracted_globals": parsed.get("extracted_globals", {}),
                    "suggested_blocks": parsed.get("suggested_blocks", []),
                },
            )
        except Exception as e:
            logger.info(f"prompt_import_runs not stored (ignored): {e}")
        return {"success": True, **parsed}
    except Exception as e:
        logger.error(f"Erro ao parse prompt_master: {e}")
        raise HTTPException(status_code=500, detail=str(e))

