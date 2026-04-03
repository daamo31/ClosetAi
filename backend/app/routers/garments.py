"""
routers/garments.py — Endpoint: POST /api/garments/upload
Flujo:
  1. Flutter sube la foto + metadata de la prenda
  2. rembg elimina el fondo → PNG transparente
  3. Se sube la imagen procesada a Supabase Storage
  4. Se guarda la prenda en PostgreSQL
  5. Se devuelve el objeto prenda completo
"""
import uuid
import logging
from decimal import Decimal

from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.garment import Garment
from app.schemas.garment import GarmentResponse, GarmentListResponse
from app.services.image_service import remove_background
from app.services.storage_service import upload_garment_image, delete_garment_image
from app.auth import get_current_user
from app.utils.subscription import check_garment_limit, get_garment_count, can_add_garment, FREE_GARMENT_LIMIT

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/garments", tags=["👕 Prendas"])

# Tamaño máximo de imagen: 10MB
MAX_IMAGE_SIZE = 10 * 1024 * 1024
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp", "image/heic"}


@router.post("/upload", response_model=GarmentResponse, status_code=status.HTTP_201_CREATED)
async def upload_garment(
    # ── Imagen ─────────────────────────────────────────────────────────────
    image: UploadFile = File(..., description="Foto de la prenda (JPG, PNG, WEBP)"),
    # ── Metadata de la prenda ──────────────────────────────────────────────
    name:           str   = Form(...,        description="Nombre descriptivo, ej: 'Camisa azul Oxford'"),
    category:       str   = Form(...,        description="top | bottom | shoes | outerwear | accessory"),
    color:          str   = Form(...,        description="Color principal, ej: 'Azul marino'"),
    season:         str   = Form("all",      description="spring | summer | autumn | winter | all"),
    occasion:       str   = Form("casual",   description="work | casual | sport | formal"),
    purchase_price: float = Form(0.0,        description="Precio de compra en euros (para calcular CPW)"),
    # ── Dependencias ──────────────────────────────────────────────────────
    db:      AsyncSession = Depends(get_db),
    user_id: uuid.UUID    = Depends(get_current_user),
):
    """
    Sube una nueva prenda al armario.

    - Elimina el fondo de la foto automáticamente
    - Guarda la prenda en la base de datos
    - Controla el límite de 30 prendas del plan gratuito
    """
    # ── 1. Verificar límite freemium ───────────────────────────────────────
    await check_garment_limit(db, user_id)

    # ── 2. Validar imagen ──────────────────────────────────────────────────
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Formato no soportado: {image.content_type}. Usa JPG, PNG o WEBP.",
        )

    image_bytes = await image.read()
    if len(image_bytes) > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"La imagen es demasiado grande ({len(image_bytes)/1024/1024:.1f}MB). Máximo: 10MB.",
        )

    # ── 3. Eliminar fondo ──────────────────────────────────────────────────
    logger.info(f"Procesando imagen '{image.filename}' ({len(image_bytes)/1024:.1f}KB)...")
    try:
        processed_image = await remove_background(image_bytes)
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc))

    # ── 4. Reservar ID y subir imagen ─────────────────────────────────────
    garment_id = uuid.uuid4()
    try:
        image_url = await upload_garment_image(
            processed_image, str(user_id), str(garment_id)
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(exc))

    # ── 5. Guardar en base de datos ───────────────────────────────────────
    garment = Garment(
        id=garment_id,
        user_id=user_id,
        name=name.strip(),
        category=category,
        color=color.strip(),
        season=season,
        occasion=occasion,
        purchase_price=Decimal(str(purchase_price)),
        image_url=image_url,
        times_used=0,
        cost_per_wear=Decimal("0.00"),
    )
    db.add(garment)
    await db.commit()
    await db.refresh(garment)

    logger.info(f"Prenda creada: '{garment.name}' ({garment.id}) para usuario {user_id}")
    return garment


@router.get("/", response_model=GarmentListResponse)
async def list_garments(
    category: str | None = None,
    occasion: str | None = None,
    db:      AsyncSession = Depends(get_db),
    user_id: uuid.UUID    = Depends(get_current_user),
):
    """Devuelve todas las prendas del armario del usuario, con filtros opcionales."""
    query = select(Garment).where(Garment.user_id == user_id)

    if category:
        query = query.where(Garment.category == category)
    if occasion:
        query = query.where(Garment.occasion == occasion)

    query = query.order_by(Garment.created_at.desc())
    result = await db.execute(query)
    garments = result.scalars().all()

    total = await get_garment_count(db, user_id)
    return GarmentListResponse(
        garments=garments,
        total=total,
        free_limit=FREE_GARMENT_LIMIT,
        can_add_more=can_add_garment(total),
    )


@router.delete("/{garment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_garment(
    garment_id: uuid.UUID,
    db:      AsyncSession = Depends(get_db),
    user_id: uuid.UUID    = Depends(get_current_user),
):
    """Elimina una prenda del armario (y su imagen de Supabase Storage)."""
    result = await db.execute(
        select(Garment).where(Garment.id == garment_id, Garment.user_id == user_id)
    )
    garment = result.scalar_one_or_none()

    if not garment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Prenda no encontrada")

    await delete_garment_image(str(user_id), str(garment_id))
    await db.delete(garment)
    await db.commit()
