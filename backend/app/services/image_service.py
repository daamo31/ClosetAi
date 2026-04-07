"""
services/image_service.py — Eliminación de fondo con rembg
Recibe bytes de una imagen → devuelve PNG sin fondo (transparente)

La librería rembg usa el modelo U2Net (descargado automáticamente en el primer uso,
pre-cacheado en el Dockerfile para evitar esperas en Render.com)
"""
import io
import logging
import asyncio
import time
from PIL import Image

logger = logging.getLogger(__name__)

_rembg_session = None
_rembg_lock = asyncio.Lock()


async def _get_rembg_session():
    """Inicializa una sola vez la sesión del modelo para evitar recargas costosas."""
    global _rembg_session
    if _rembg_session is not None:
        return _rembg_session

    async with _rembg_lock:
        if _rembg_session is None:
            from rembg import new_session

            # u2netp es más ligero y rápido para entornos pequeños como Render free.
            _rembg_session = await asyncio.to_thread(new_session, "u2netp")
            logger.info("Modelo rembg cargado en memoria (u2netp)")

    return _rembg_session


async def remove_background(image_bytes: bytes) -> bytes:
    """
    Elimina el fondo de una imagen usando rembg (modelo U2Net).

    Args:
        image_bytes: Bytes de la imagen original (JPG, PNG, WEBP, etc.)

    Returns:
        Bytes de un PNG con el fondo eliminado (transparencia RGBA)
    """
    try:
        # Importación diferida para evitar carga del modelo en el startup
        from rembg import remove

        started_at = time.perf_counter()
        session = await _get_rembg_session()
        output_bytes = await asyncio.to_thread(remove, image_bytes, session)

        # Asegurar que la imagen de salida es un PNG válido con canal alpha
        img = Image.open(io.BytesIO(output_bytes)).convert("RGBA")

        # Optimizar: recortar transparencia excesiva alrededor de la prenda
        img = _crop_to_content(img)

        # Serializar como PNG
        buffer = io.BytesIO()
        img.save(buffer, format="PNG", optimize=True)
        buffer.seek(0)

        logger.info(
            f"Fondo eliminado. Tamaño original: {len(image_bytes)/1024:.1f}KB "
            f"→ Resultado: {buffer.getbuffer().nbytes/1024:.1f}KB "
            f"en {time.perf_counter() - started_at:.2f}s"
        )
        return buffer.read()

    except ImportError:
        logger.error("rembg no está instalado. Instala con: pip install rembg")
        raise RuntimeError("Servicio de eliminación de fondo no disponible")
    except Exception as exc:
        logger.error(f"Error eliminando fondo: {exc}")
        raise RuntimeError(f"No se pudo procesar la imagen: {exc}")


def _crop_to_content(img: Image.Image, padding: int = 10) -> Image.Image:
    """
    Recorta el espacio transparente alrededor de la prenda.
    Añade un pequeño padding para que no quede demasiado ajustado.
    """
    try:
        # Obtener el bounding box del contenido no-transparente
        bbox = img.getbbox()
        if bbox is None:
            return img  # imagen completamente transparente → devolver tal cual

        left   = max(0, bbox[0] - padding)
        top    = max(0, bbox[1] - padding)
        right  = min(img.width,  bbox[2] + padding)
        bottom = min(img.height, bbox[3] + padding)

        return img.crop((left, top, right, bottom))
    except Exception:
        return img  # Si falla el recorte, devolver la imagen original
