import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://gwjcgzeybqiyqezuswpt.supabase.co")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

    # Storage
    BUCKET_NAME: str = os.getenv("BUCKET_NAME", "arquivos_tools")

    # File Upload
    MAX_FILE_SIZE: int = 50 * 1024 * 1024  # 50MB

    # Tipos de arquivo aceitos por categoria
    ALLOWED_AUDIO_TYPES = [".mp3", ".ogg", ".wav", ".m4a", ".aac"]
    ALLOWED_VIDEO_TYPES = [".mp4", ".mov", ".avi", ".mkv", ".webm"]
    ALLOWED_IMAGE_TYPES = [".jpg", ".jpeg", ".png", ".gif", ".webp"]
    ALLOWED_DOCUMENT_TYPES = [".pdf", ".doc", ".docx", ".xls", ".xlsx", ".txt"]

    @property
    def all_allowed_types(self):
        return (
            self.ALLOWED_AUDIO_TYPES
            + self.ALLOWED_VIDEO_TYPES
            + self.ALLOWED_IMAGE_TYPES
            + self.ALLOWED_DOCUMENT_TYPES
        )


settings = Settings()

