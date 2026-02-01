from fastapi import APIRouter, HTTPException, Query
import logging

from saas_tools.services.supabase_service import supabase_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["dashboard"])


@router.get("/dashboard/ia-insights")
def get_ia_insights(
    tenant_id: str = Query(..., description="ID do tenant"),
    data: str = Query(..., description="Data no formato YYYY-MM-DD"),
):
    """
    Retorna os insights do dia (Geral, Ligações, Conversas, Agendamentos)
    da tabela ia_insights. Os 4 cards usam isso; no front, Agendamentos
    usa como base o total que já está no dashboard (KPI).
    """
    try:
        row = supabase_service.get_ia_insights(tenant_id, data)
        if not row:
            return {
                "success": True,
                "data": {
                    "geral": "",
                    "calls": "",
                    "conversas": "",
                    "agendamentos": "",
                    "consideracoes": "",
                },
                "source": "ia_insights",
                "message": "Nenhum registro para esta data.",
            }
        return {
            "success": True,
            "data": {
                "geral": row.get("geral") or "",
                "calls": row.get("calls") or "",
                "conversas": row.get("conversas") or "",
                "agendamentos": row.get("agendamentos") or "",
                "consideracoes": row.get("consideracoes") or "",
            },
            "source": "ia_insights",
        }
    except Exception as e:
        logger.error(f"Erro ao buscar ia_insights: {e}")
        raise HTTPException(status_code=500, detail=str(e))
