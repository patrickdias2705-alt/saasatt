import uuid
from datetime import datetime
from pathlib import Path
import logging

from supabase import create_client
from supabase._sync.client import SupabaseException

from saas_tools.config import settings

logger = logging.getLogger(__name__)


class FileService:
    """Service para operações com arquivos (igual vapi-tools-manager)."""

    def __init__(self):
        self.client = None
        if settings.SUPABASE_KEY:
            self.client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        self.bucket_name = settings.BUCKET_NAME

    def _require_client(self):
        if self.client is None:
            raise SupabaseException("SUPABASE_KEY is required (defina SUPABASE_KEY no ambiente do saas_server)")
        return self.client

    async def upload_file(self, file_content: bytes, filename: str, tenant_id: str, content_type: str) -> dict:
        try:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            unique_id = str(uuid.uuid4())[:8]
            safe_filename = filename.replace(" ", "_")
            final_filename = f"{timestamp}_{unique_id}_{safe_filename}"

            file_path = f"{tenant_id}/{final_filename}"

            self._require_client().storage.from_(self.bucket_name).upload(
                path=file_path,
                file=file_content,
                file_options={"content-type": content_type},
            )

            public_url = self._require_client().storage.from_(self.bucket_name).get_public_url(file_path)

            file_extension = Path(filename).suffix.lower()
            file_type = self._get_file_type(file_extension)

            return {
                "file_url": public_url,
                "file_name": final_filename,
                "file_type": file_type,
                "file_size": len(file_content),
            }
        except Exception as e:
            logger.error(f"Erro ao fazer upload: {e}")
            raise

    def _get_file_type(self, extension: str) -> str:
        if extension in settings.ALLOWED_AUDIO_TYPES:
            return "audio"
        if extension in settings.ALLOWED_VIDEO_TYPES:
            return "video"
        if extension in settings.ALLOWED_IMAGE_TYPES:
            return "imagem"
        if extension in settings.ALLOWED_DOCUMENT_TYPES:
            return "arquivo"
        return "arquivo"

    def validate_file(self, filename: str, file_size: int) -> tuple[bool, str]:
        if file_size > settings.MAX_FILE_SIZE:
            return False, f"Arquivo muito grande. Máximo: {settings.MAX_FILE_SIZE / 1024 / 1024}MB"

        extension = Path(filename).suffix.lower()
        if extension not in settings.all_allowed_types:
            return False, f"Tipo de arquivo não permitido: {extension}"

        return True, ""


file_service = FileService()

