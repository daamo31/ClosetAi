"""
config.py — Configuración central de la aplicación
Carga todas las variables de entorno desde el archivo .env
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── Supabase ───────────────────────────────────────────────────────────────
    SUPABASE_URL: str
    SUPABASE_KEY: str           # anon/public key (segura para el cliente)
    SUPABASE_JWT_SECRET: str    # JWT secret para verificar tokens de usuario

    # ── Base de Datos (conexión directa a PostgreSQL de Supabase) ──────────────
    DATABASE_URL: str           # postgresql+asyncpg://user:pass@host:5432/postgres

    # ── Groq API (LLM gratuito) ───────────────────────────────────────────────
    GROQ_API_KEY: str
    GROQ_MODEL: str = "llama3-70b-8192"

    # ── OpenWeatherMap ─────────────────────────────────────────────────────────
    OPENWEATHER_API_KEY: str

    # ── App ───────────────────────────────────────────────────────────────────
    APP_ENV: str = "development"
    SUPABASE_STORAGE_BUCKET: str = "garment-images"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Retorna una instancia singleton de Settings (cacheada)."""
    return Settings()


# Instancia global para importar directamente
settings = get_settings()
