"""
models/garment.py — Tabla de prendas del armario
Cada prenda pertenece a un usuario y tiene métricas de coste por uso (CPW)
"""
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import String, DateTime, Numeric, Integer, func, Index
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class Garment(Base):
    """
    Representa una prenda de ropa en el armario del usuario.

    Campos clave de negocio:
      - purchase_price: Lo que pagó el usuario por la prenda
      - times_used:     Cuántas veces ha sido llevada (incrementado por /log-usage)
      - cost_per_wear:  purchase_price / times_used  → mide la "rentabilidad" de la prenda
    """
    __tablename__ = "garments"

    # ── Identificadores ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )

    # ── Descripción ───────────────────────────────────────────────────────────
    name: Mapped[str] = mapped_column(String(200), nullable=False)

    # Categoría: top | bottom | shoes | outerwear | accessory
    category: Mapped[str] = mapped_column(String(50), nullable=False)

    color: Mapped[str] = mapped_column(String(100), nullable=False)

    # Temporada: spring | summer | autumn | winter | all
    season: Mapped[str] = mapped_column(String(50), nullable=False, default="all")

    # Ocasión: casual | work | sport | formal
    occasion: Mapped[str] = mapped_column(String(50), nullable=False, default="casual")

    # ── Imagen ────────────────────────────────────────────────────────────────
    # URL pública en Supabase Storage (imagen sin fondo, formato PNG)
    image_url: Mapped[str] = mapped_column(String(1000), nullable=True)

    # ── Métricas Coste por Uso (CPW) ──────────────────────────────────────────
    purchase_price: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), nullable=False, default=Decimal("0.00")
    )
    times_used: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    cost_per_wear: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), nullable=False, default=Decimal("0.00"),
        comment="Calculado automáticamente: purchase_price / times_used"
    )

    # ── Timestamps ────────────────────────────────────────────────────────────
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(),
        onupdate=func.now(), nullable=False
    )

    # ── Índices compuestos para queries frecuentes ─────────────────────────────
    __table_args__ = (
        Index("ix_garments_user_category", "user_id", "category"),
        Index("ix_garments_user_occasion", "user_id", "occasion"),
        Index("ix_garments_user_season", "user_id", "season"),
    )

    def recalculate_cpw(self) -> None:
        """Recalcula el coste por uso después de registrar un nuevo uso."""
        if self.times_used > 0 and self.purchase_price > 0:
            self.cost_per_wear = Decimal(
                str(float(self.purchase_price) / self.times_used)
            ).quantize(Decimal("0.01"))

    def __repr__(self) -> str:
        return f"<Garment '{self.name}' [{self.category}] CPW={self.cost_per_wear}€>"
