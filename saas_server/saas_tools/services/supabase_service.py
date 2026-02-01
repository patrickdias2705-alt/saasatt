from datetime import datetime, timedelta
from supabase import create_client, Client
from supabase._sync.client import SupabaseException
from typing import List, Optional, Dict, Any
import logging

from saas_tools.config import settings

logger = logging.getLogger(__name__)


class SupabaseService:
    """Service para operações com Supabase (igual vapi-tools-manager)."""

    def __init__(self):
        # Não explodir o servidor se a key não estiver setada.
        # A UI pode subir, e a API vai falhar com mensagem clara até configurar a env.
        self.client: Client | None = None
        if settings.SUPABASE_KEY:
            self.client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

    def _require_client(self) -> Client:
        if self.client is None:
            raise SupabaseException("SUPABASE_KEY is required (defina SUPABASE_KEY no ambiente do saas_server)")
        return self.client

    def get_tools_by_tenant(self, tenant_id: str) -> List[Dict[str, Any]]:
        try:
            response = (
                self._require_client().table("vapi_tools")
                .select("*")
                .eq("tenant_id", tenant_id)
                .eq("is_active", True)
                .order("created_at", desc=True)
                .execute()
            )
            return response.data
        except Exception as e:
            logger.error(f"Erro ao buscar tools: {e}")
            raise

    def get_tool_by_id(self, tool_id: str, tenant_id: str) -> Optional[Dict[str, Any]]:
        try:
            response = (
                self._require_client().table("vapi_tools")
                .select("*")
                .eq("id", tool_id)
                .eq("tenant_id", tenant_id)
                .single()
                .execute()
            )
            return response.data
        except Exception as e:
            logger.error(f"Erro ao buscar tool: {e}")
            return None

    def create_tool(self, tool_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            response = self._require_client().table("vapi_tools").insert(tool_data).execute()
            return response.data[0] if response.data else None
        except Exception as e:
            logger.error(f"Erro ao criar tool: {e}")
            raise

    def update_tool(self, tool_id: str, tenant_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            response = (
                self._require_client().table("vapi_tools")
                .update(update_data)
                .eq("id", tool_id)
                .eq("tenant_id", tenant_id)
                .execute()
            )
            return response.data[0] if response.data else None
        except Exception as e:
            logger.error(f"Erro ao atualizar tool: {e}")
            raise

    def delete_tool(self, tool_id: str, tenant_id: str) -> bool:
        try:
            response = (
                self._require_client().table("vapi_tools")
                .update({"is_active": False})
                .eq("id", tool_id)
                .eq("tenant_id", tenant_id)
                .execute()
            )
            return len(response.data) > 0
        except Exception as e:
            logger.error(f"Erro ao deletar tool: {e}")
            raise

    def get_instances_by_tenant(self, tenant_id: str) -> List[Dict[str, Any]]:
        try:
            response = (
                self._require_client().table("whatsapp_instances")
                .select("id, instance_name, phone_number, status")
                .eq("tenant_id", tenant_id)
                .eq("status", "conectada")
                .execute()
            )
            return response.data
        except Exception as e:
            logger.error(f"Erro ao buscar instâncias: {e}")
            raise

    # ============================================================================
    # Assistants: profiles / flows
    # ============================================================================
    def get_assistant_profile(self, assistant_id: str) -> Optional[Dict[str, Any]]:
        try:
            response = (
                self._require_client()
                .table("assistant_profiles")
                .select("*")
                .eq("assistant_id", assistant_id)
                .single()
                .execute()
            )
            return response.data
        except Exception as e:
            # If not found, Supabase raises; we treat as empty profile
            logger.info(f"assistant_profiles not found for assistant_id={assistant_id}: {e}")
            return None

    def upsert_assistant_profile(self, assistant_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            payload = {"assistant_id": assistant_id, **data}
            response = (
                self._require_client()
                .table("assistant_profiles")
                .upsert(payload, on_conflict="assistant_id")
                .execute()
            )
            return response.data[0] if response.data else payload
        except Exception as e:
            logger.error(f"Erro ao upsert assistant_profile: {e}")
            raise

    def get_assistant_flow(self, assistant_id: str) -> Optional[Dict[str, Any]]:
        try:
            response = (
                self._require_client()
                .table("assistant_flows")
                .select("*")
                .eq("assistant_id", assistant_id)
                .single()
                .execute()
            )
            return response.data
        except Exception as e:
            logger.info(f"assistant_flows not found for assistant_id={assistant_id}: {e}")
            return None

    def upsert_assistant_flow(self, assistant_id: str, flow_json: Dict[str, Any], meta: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        try:
            payload: Dict[str, Any] = {"assistant_id": assistant_id, "flow_json": flow_json}
            if meta:
                payload.update(meta)
            response = (
                self._require_client()
                .table("assistant_flows")
                .upsert(payload, on_conflict="assistant_id")
                .execute()
            )
            return response.data[0] if response.data else payload
        except Exception as e:
            logger.error(f"Erro ao upsert assistant_flow: {e}")
            raise

    def create_prompt_import_run(self, assistant_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            payload = {"assistant_id": assistant_id, **data}
            response = self._require_client().table("prompt_import_runs").insert(payload).execute()
            return response.data[0] if response.data else payload
        except Exception as e:
            logger.error(f"Erro ao criar prompt_import_run: {e}")
            raise

    # ============================================================================
    # Dashboard: ia_insights – tabela que já existe no Supabase (geral, calls, conversas, agendamentos, consideracoes)
    # Grazi Insights lê daqui para organizar os 4 cards. Filtro por tenant_id + criado_dia (dia).
    # ============================================================================
    def get_ia_insights(self, tenant_id: str, data_filtro: str) -> Optional[Dict[str, Any]]:
        """
        Retorna um registro de ia_insights para o tenant e a data.
        data_filtro: YYYY-MM-DD. Tabela usa criado_dia (timestamptz); filtra pelo dia.
        Retorno: { geral, calls, conversas, agendamentos, consideracoes }.
        """
        client = self._require_client()
        d = datetime.strptime(data_filtro, "%Y-%m-%d")
        start = d.strftime("%Y-%m-%dT00:00:00")
        end = (d + timedelta(days=1)).strftime("%Y-%m-%dT00:00:00")
        try:
            response = (
                client.table("ia_insights")
                .select("geral, calls, conversas, agendamentos, consideracoes")
                .eq("tenant_id", tenant_id)
                .gte("criado_dia", start)
                .lt("criado_dia", end)
                .order("criado_dia", desc=True)
                .limit(1)
                .execute()
            )
            if response.data and len(response.data) > 0:
                return _normalize_ia_insights_row(response.data[0])
        except Exception as e:
            logger.warning("ia_insights: tenant_id=%s data=%s: %s", tenant_id, data_filtro, e)
        return None


def _normalize_ia_insights_row(row: Dict[str, Any]) -> Dict[str, Any]:
    """Garante chaves esperadas; consideracoes pode não existir."""
    return {
        "geral": row.get("geral") or "",
        "calls": row.get("calls") or "",
        "conversas": row.get("conversas") or "",
        "agendamentos": row.get("agendamentos") or "",
        "consideracoes": row.get("consideracoes") or "",
    }


supabase_service = SupabaseService()

