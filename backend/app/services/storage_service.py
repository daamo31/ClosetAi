"""
services/storage_service.py — Subida de imágenes a Supabase Storage
El bucket 'garment-images' almacena los PNG procesados (sin fondo).

Estructura de archivos en el bucket:
  garment-images/
    └── {user_id}/
          └── {garment_id}.png
"""
import logging
from supabase import create_client, Client
from app.config import settings

logger = logging.getLogger(__name__)

# ── Cliente Supabase (instancia única) ───────────────────────────────────────
_supabase: Client | None = None


def _get_supabase() -> Client:
    global _supabase
    if _supabase is None:
        _supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    return _supabase


BUCKET = settings.SUPABASE_STORAGE_BUCKET


async def upload_garment_image(
    image_bytes: bytes,
    user_id: str,
    garment_id: str,
) -> str:
    """
    Sube la imagen procesada al bucket de Supabase Storage.

    Args:
        image_bytes: PNG sin fondo (bytes)
        user_id:     UUID del usuario como string
        garment_id:  UUID de la prenda como string

    Returns:
        URL pública de la imagen (permanente, sin autenticación)
    """
    file_path = f"{user_id}/{garment_id}.png"
    supabase = _get_supabase()

    try:
        # Subir archivo (upsert=True permite re-subir si ya existe)
        supabase.storage.from_(BUCKET).upload(
            path=file_path,
            file=image_bytes,
            file_options={
                "content-type": "image/png",
                "upsert": "true",
            },
        )

        # Obtener URL pública (el bucket debe ser público en Supabase)
        url_response = supabase.storage.from_(BUCKET).get_public_url(file_path)
        logger.info(f"Imagen subida: {file_path} → {url_response}")
        return url_response

    except Exception as exc:
        logger.error(f"Error subiendo imagen a Supabase Storage: {exc}")
        raise RuntimeError(f"No se pudo subir la imagen: {exc}")


async def delete_garment_image(user_id: str, garment_id: str) -> None:
    """Elimina la imagen de una prenda al borrarla del armario."""
    file_path = f"{user_id}/{garment_id}.png"
    supabase = _get_supabase()

    try:
        supabase.storage.from_(BUCKET).remove([file_path])
        logger.info(f"Imagen eliminada: {file_path}")
    except Exception as exc:
        # No es crítico si falla el borrado de imagen
        logger.warning(f"No se pudo eliminar imagen {file_path}: {exc}")
