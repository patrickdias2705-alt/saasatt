from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from typing import Any, Dict
import logging

from saas_tools.models.schemas import ToolCreate, ToolUpdate
from saas_tools.services.supabase_service import supabase_service
from saas_tools.services.file_service import file_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["tools"])


@router.get("/tools/{tenant_id}")
async def get_tools(tenant_id: str):
    """Busca todas as tools de um tenant (igual vapi-tools-manager)."""
    try:
        tools = supabase_service.get_tools_by_tenant(tenant_id)
        return {"success": True, "total": len(tools), "tools": tools}
    except Exception as e:
        logger.error(f"Erro ao buscar tools: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/tools")
async def create_tool(tool: ToolCreate):
    """Cria uma nova tool (igual vapi-tools-manager)."""
    try:
        if tool.tool_type == "mensagem" and not tool.instancia:
            raise HTTPException(status_code=400, detail="Instância é obrigatória para tools de mensagem")

        tool_data = tool.model_dump()
        created_tool = supabase_service.create_tool(tool_data)
        if not created_tool:
            raise HTTPException(status_code=500, detail="Erro ao criar tool")

        return {"success": True, "message": "Tool criada com sucesso", "tool": created_tool}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao criar tool: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/tools/{tool_id}")
async def update_tool(tool_id: str, tool: ToolUpdate):
    """Atualiza uma tool existente (igual vapi-tools-manager)."""
    try:
        update_data = {k: v for k, v in tool.model_dump().items() if v is not None}
        if not update_data:
            raise HTTPException(status_code=400, detail="Nenhum dado para atualizar")

        from datetime import datetime

        update_data["updated_at"] = datetime.now().isoformat()

        existing_tool = supabase_service.get_tool_by_id(tool_id, "")
        if not existing_tool:
            raise HTTPException(status_code=404, detail="Tool não encontrada")

        tenant_id = existing_tool.get("tenant_id")
        updated_tool = supabase_service.update_tool(tool_id, tenant_id, update_data)
        if not updated_tool:
            raise HTTPException(status_code=500, detail="Erro ao atualizar tool")

        return {"success": True, "message": "Tool atualizada com sucesso", "tool": updated_tool}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao atualizar tool: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/tools/{tool_id}")
async def delete_tool(tool_id: str, tenant_id: str):
    """Desativa uma tool (soft delete) (igual vapi-tools-manager)."""
    try:
        success = supabase_service.delete_tool(tool_id, tenant_id)
        if not success:
            raise HTTPException(status_code=404, detail="Tool não encontrada")
        return {"success": True, "message": "Tool desativada com sucesso"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao deletar tool: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/tools/upload")
async def upload_file(file: UploadFile = File(...), tenant_id: str = Form(...)):
    """Upload de arquivo para Supabase Storage (igual vapi-tools-manager)."""
    try:
        file_content = await file.read()
        is_valid, error_msg = file_service.validate_file(file.filename, len(file_content))
        if not is_valid:
            raise HTTPException(status_code=400, detail=error_msg)

        result = await file_service.upload_file(
            file_content=file_content,
            filename=file.filename,
            tenant_id=tenant_id,
            content_type=file.content_type or "application/octet-stream",
        )
        return {"success": True, **result}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro no upload: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/instances/{tenant_id}")
async def get_instances(tenant_id: str):
    """Busca instâncias WhatsApp conectadas de um tenant (igual vapi-tools-manager)."""
    try:
        instances = supabase_service.get_instances_by_tenant(tenant_id)
        return {"success": True, "total": len(instances), "instances": instances}
    except Exception as e:
        logger.error(f"Erro ao buscar instâncias: {e}")
        raise HTTPException(status_code=500, detail=str(e))

