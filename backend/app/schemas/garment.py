"""
schemas/garment.py — Pydantic v2 schemas para Garment
Define la forma exacta de los datos de entrada y salida en los endpoints
"""
from pydantic import BaseModel, Field, field_validator
from uuid import UUID
from decimal import Decimal
from datetime import datetime
from typing import Optional

# Valores permitidos para cada campo enum
VALID_CATEGORIES = {"top", "bottom", "shoes", "outerwear", "accessory"}
VALID_SEASONS    = {"spring", "summer", "autumn", "winter", "all"}
VALID_OCCASIONS  = {"casual", "work", "sport", "formal"}


class GarmentCreate(BaseModel):
    """Datos que envía Flutter al subir una prenda (form fields)."""
    name: str = Field(..., min_length=1, max_length=200, examples=["Camisa azul Oxford"])
    category: str = Field(..., examples=["top"])
    color: str = Field(..., min_length=1, max_length=100, examples=["Azul marino"])
    season: str = Field(default="all", examples=["all"])
    occasion: str = Field(default="casual", examples=["work"])
    purchase_price: float = Field(default=0.0, ge=0, examples=[29.99])

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        if v not in VALID_CATEGORIES:
            raise ValueError(f"Categoría inválida. Usa: {VALID_CATEGORIES}")
        return v

    @field_validator("season")
    @classmethod
    def validate_season(cls, v: str) -> str:
        if v not in VALID_SEASONS:
            raise ValueError(f"Temporada inválida. Usa: {VALID_SEASONS}")
        return v

    @field_validator("occasion")
    @classmethod
    def validate_occasion(cls, v: str) -> str:
        if v not in VALID_OCCASIONS:
            raise ValueError(f"Ocasión inválida. Usa: {VALID_OCCASIONS}")
        return v


class GarmentResponse(BaseModel):
    """Datos que devuelve la API después de crear/consultar una prenda."""
    id: UUID
    user_id: UUID
    name: str
    category: str
    color: str
    season: str
    occasion: str
    purchase_price: Decimal
    image_url: Optional[str] = None
    times_used: int
    cost_per_wear: Decimal
    created_at: datetime

    model_config = {"from_attributes": True}   # permite crear desde ORM


class GarmentListResponse(BaseModel):
    """Lista paginada de prendas del armario."""
    garments: list[GarmentResponse]
    total: int
    free_limit: int = 30
    can_add_more: bool
