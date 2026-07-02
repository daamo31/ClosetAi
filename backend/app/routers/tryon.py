"""
routers/tryon.py — Virtual Try-On con Replicate IDM-VTON
Soporta outfit completo: procesa las prendas secuencialmente
(resultado de una prenda = foto de entrada para la siguiente)
Orden: top → outerwear → bottom → shoes → accessory
"""
import uuid
import json
import base64
import logging
import asyncio
from typing import List

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

CATEGORY_ORDER = {"top": 0, "outerwear": 1, "bottom": 2, "shoes": 3, "accessory": 4}

MAX_POLL_SECONDS = 150
POLL_INTERVAL    = 3


async def _run_tryon(
    client: httpx.AsyncClient,
    human_img: str,        # data URL o URL pública
    garment: Garment,
) -> str:
    """Llama a IDM-VTON para una sola prenda. Devuelve la URL del resultado."""
    category = CATEGORY_MAP.get(str(garment.category), "upper_body")
    headers = {
        "Authorization": f"Token {settings.REPLICATE_API_TOKEN}",
        "Content-Type":  "application/json",
        "Prefer":        "wait",
    }
    payload = {
        "input": {
            "human_img":       human_img,
            "garm_img":        garment.image_url,
            "garment_des":     f"{garment.color} {garment.name}",
            "category":        category,
            "is_checked":      True,
            "is_checked_crop": False,
            "denoise_steps":   30,
            "seed":            42,
        }
    }

    resp = await client.post(
        "https://api.replicate.com/v1/models/yisol/idm-vton/predictions",
        headers=headers, json=payload,
    )
    if resp.status_code not in (200, 201):
        raise HTTPException(status_code=502, detail=f"Error Replicate: {resp.text[:300]}")

    prediction = resp.json()
    pred_id    = prediction["id"]
    pred_status = prediction.get("status", "starting")

    poll_headers = {"Authorization": f"Token {settings.REPLICATE_API_TOKEN}"}
    elapsed = 0
    while pred_status not in ("succeeded", "failed", "canceled") and elapsed < MAX_POLL_SECONDS:
        await asyncio.sleep(POLL_INTERVAL)
        elapsed += POLL_INTERVAL
        poll = await client.get(
            f"https://api.replicate.com/v1/predictions/{pred_id}",
            headers=poll_headers,
        )
        prediction  = poll.json()
        pred_status = prediction.get("status", "")
        logger.info("Try-on [%s] %s — %s", garment.name, pred_id, pred_status)

    if pred_status != "succeeded":
        raise HTTPException(status_code=504, detail=f"Try-on timeout para '{garment.name}' (estado: {pred_status}).")

    output = prediction.get("output")
    url = output[0] if isinstance(output, list) else output
    if not url:
        raise HTTPException(status_code=502, detail="Replicate no devolvió imagen.")
    return url


@router.post("", status_code=status.HTTP_200_OK)
async def virtual_tryon(
    person_image: UploadFile = File(..., description="Foto de la persona (JPG/PNG)"),
    garment_ids:  str        = Form(..., description='JSON array de UUIDs, ej: ["uuid1","uuid2"]'),
    db:           AsyncSession = Depends(get_db),
    user_id:      uuid.UUID    = Depends(get_current_user),
):
    """
    Genera un try-on del outfit completo usando Replicate IDM-VTON.
    Procesa las prendas en orden (top → bottom) encadenando los resultados.
    """
    if not settings.REPLICATE_API_TOKEN:
        raise HTTPException(status_code=503, detail="REPLICATE_API_TOKEN no configurado.")

    # ── 1. Parsear IDs ────────────────────────────────────────────────────
    try:
        ids: List[str] = json.loads(garment_ids) if garment_ids.startswith("[") else [g.strip() for g in garment_ids.split(",")]
    except Exception:
        raise HTTPException(status_code=400, detail="garment_ids debe ser un array JSON.")

    # ── 2. Cargar prendas (solo las que tienen imagen) ────────────────────
    garments = []
    for gid in ids:
        res = await db.execute(
            select(Garment).where(Garment.id == uuid.UUID(gid), Garment.user_id == user_id)
        )
        g = res.scalar_one_or_none()
        if g and g.image_url:
            garments.append(g)

    if not garments:
        raise HTTPException(status_code=400, detail="Ninguna prenda del outfit tiene imagen.")

    # Ordenar: upper_body primero para resultados más naturales
    garments.sort(key=lambda g: CATEGORY_ORDER.get(str(g.category), 9))

    # ── 3. Foto de la persona → base64 ───────────────────────────────────
    person_bytes = await person_image.read()
    if len(person_bytes) > 10 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Foto demasiado grande (máx 10 MB).")

    mime = person_image.content_type or "image/jpeg"
    current_human = f"data:{mime};base64,{base64.b64encode(person_bytes).decode()}"

    # ── 4. Procesar prendas secuencialmente ──────────────────────────────
    result_url = None
    names = [g.name for g in garments]
    logger.info("Try-on outfit completo: %s prendas → %s", len(garments), names)

    async with httpx.AsyncClient(timeout=160.0) as client:
        for i, garment in enumerate(garments):
            logger.info("Try-on prenda %d/%d: %s", i + 1, len(garments), garment.name)
            result_url = await _run_tryon(client, current_human, garment)

            # Si quedan prendas, descargar el resultado para usarlo como nueva foto base
            if i < len(garments) - 1:
                img_resp = await client.get(result_url, timeout=30.0)
                img_bytes = img_resp.content
                current_human = f"data:image/webp;base64,{base64.b64encode(img_bytes).decode()}"

    return {
        "result_url":  result_url,
        "garments":    names,
        "total_steps": len(garments),
    }
