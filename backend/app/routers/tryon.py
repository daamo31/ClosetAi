"""
routers/tryon.py — Virtual Try-On con Replicate IDM-VTON
Recibe foto del usuario + garment_id → devuelve imagen con la prenda puesta
"""
import uuid
import base64
import logging
import asyncio

import httpx
from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.garment import Garment
from app.auth import get_current_user
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/tryon", tags=["👗 Try-On"])

CATEGORY_MAP = {
    "top":       "upper_body",
    "outerwear": "upper_body",
    "accessory": "upper_body",
    "bottom":    "lower_body",
    "shoes":     "lower_body",
}

MAX_POLL_SECONDS = 120
POLL_INTERVAL    = 3


@router.post("", status_code=status.HTTP_200_OK)
async def virtual_tryon(
    person_image: UploadFile = File(..., description="Foto de la persona (JPG/PNG)"),
    garment_id:   str        = Form(..., description="UUID de la prenda del armario"),
    db:           AsyncSession = Depends(get_db),
    user_id:      uuid.UUID    = Depends(get_current_user),
):
    """
    Genera una imagen de prueba virtual usando Replicate IDM-VTON.
    - Recibe la foto del usuario y el ID de una prenda del armario
    - Llama a IDM-VTON y devuelve la URL de la imagen resultante
    """
    if not settings.REPLICATE_API_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="REPLICATE_API_TOKEN no configurado en el servidor.",
        )

    # ── 1. Obtener prenda del armario ─────────────────────────────────────
    result = await db.execute(
        select(Garment).where(Garment.id == uuid.UUID(garment_id), Garment.user_id == user_id)
    )
    garment = result.scalar_one_or_none()
    if not garment:
        raise HTTPException(status_code=404, detail="Prenda no encontrada.")
    if not garment.image_url:
        raise HTTPException(status_code=400, detail="La prenda no tiene imagen.")

    category = CATEGORY_MAP.get(garment.category, "upper_body")

    # ── 2. Convertir foto de persona a base64 ─────────────────────────────
    person_bytes = await person_image.read()
    if len(person_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Foto demasiado grande (máx 10 MB).")

    mime = person_image.content_type or "image/jpeg"
    person_b64 = base64.b64encode(person_bytes).decode()
    person_data_url = f"data:{mime};base64,{person_b64}"

    # ── 3. Llamar a Replicate IDM-VTON ────────────────────────────────────
    headers = {
        "Authorization": f"Bearer {settings.REPLICATE_API_TOKEN}",
        "Content-Type": "application/json",
        "Prefer": "wait",   # espera hasta 60s en la misma conexión
    }
    payload = {
        "input": {
            "human_img":     person_data_url,
            "garm_img":      garment.image_url,
            "garment_des":   f"{garment.color} {garment.name}",
            "category":      category,
            "is_checked":    True,
            "is_checked_crop": False,
            "denoise_steps": 30,
            "seed":          42,
        }
    }

    async with httpx.AsyncClient(timeout=130.0) as client:
        # Crear predicción
        create_resp = await client.post(
            "https://api.replicate.com/v1/models/yisol/idm-vton/predictions",
            headers=headers,
            json=payload,
        )
        if create_resp.status_code not in (200, 201):
            logger.error("Replicate error: %s", create_resp.text)
            raise HTTPException(status_code=502, detail=f"Error Replicate: {create_resp.text[:300]}")

        prediction = create_resp.json()
        pred_id = prediction["id"]
        pred_status = prediction.get("status", "starting")

        # Polling si no resolvió en la misma conexión
        elapsed = 0
        poll_headers = {
            "Authorization": f"Bearer {settings.REPLICATE_API_TOKEN}",
        }
        while pred_status not in ("succeeded", "failed", "canceled") and elapsed < MAX_POLL_SECONDS:
            await asyncio.sleep(POLL_INTERVAL)
            elapsed += POLL_INTERVAL
            poll = await client.get(
                f"https://api.replicate.com/v1/predictions/{pred_id}",
                headers=poll_headers,
            )
            prediction = poll.json()
            pred_status = prediction.get("status", "")
            logger.info("Try-on polling: %s — %s", pred_id, pred_status)

    if pred_status != "succeeded":
        raise HTTPException(status_code=504, detail=f"Try-on no completado (estado: {pred_status}).")

    output = prediction.get("output")
    result_url = output[0] if isinstance(output, list) else output
    if not result_url:
        raise HTTPException(status_code=502, detail="Replicate no devolvió imagen.")

    return {"result_url": result_url, "garment": garment.name}
