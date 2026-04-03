"""
schemas/usage_log.py — Pydantic v2 schemas para UsageLog
"""
from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional
from decimal import Decimal


class UsageLogCreate(BaseModel):
    """Body del POST /api/usage/log — qué prenda se usó y cuándo."""
    garment_id: UUID
    outfit_id: Optional[UUID] = Field(
        default=None,
        description="ID del outfit generado (opcional, si viene de una sugerencia IA)"
    )
    occasion: str = Field(
        default="casual",
        examples=["work"],
        description="work | casual | sport | formal"
    )


class UsageLogResponse(BaseModel):
    """Respuesta tras registrar un uso — muestra el nuevo CPW calculado."""
    id: UUID
    garment_id: UUID
    garment_name: str
    times_used: int
    cost_per_wear: Decimal
    message: str            # "✅ Camisa azul usada 8 veces. CPW: 3.75€"

    model_config = {"from_attributes": True}
