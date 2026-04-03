"""
services/ai_service.py — Integración con Groq API (LLM gratuito)
Envía el prompt de estilista y parsea la respuesta JSON del modelo
"""
import json
import logging
import re
from fastapi import HTTPException, status
from groq import Groq
from app.config import settings
from app.models.garment import Garment

logger = logging.getLogger(__name__)

# ── Cliente Groq (instancia única) ────────────────────────────────────────────
_groq_client: Groq | None = None


def _get_client() -> Groq:
    global _groq_client
    if _groq_client is None:
        _groq_client = Groq(api_key=settings.GROQ_API_KEY)
    return _groq_client


# ── Prompt del Estilista ───────────────────────────────────────────────────────
STYLIST_PROMPT = """\
Eres un estilista personal experto con 15 años de experiencia en moda urbana y formal.
Tu misión es seleccionar el outfit perfecto del armario del usuario basándote en el clima y la ocasión.

═══════════════════════════════════
CONTEXTO DEL CLIMA
  Ciudad:      {city} ({country})
  Temperatura: {temp}°C (sensación térmica: {feels_like}°C)
  Condición:   {description}
  Humedad:     {humidity}%
═══════════════════════════════════
OCASIÓN: {occasion}
  (opciones: trabajo / cena / gimnasio / casual / evento formal)
═══════════════════════════════════
PRENDAS DISPONIBLES EN EL ARMARIO:
{garments_json}
═══════════════════════════════════

REGLAS DE SELECCIÓN:
1. Selecciona entre 3 y 5 prendas que combinen visualmente bien.
2. Asegúrate de incluir al menos: un top, un bottom (o vestido/mono) y calzado.
3. Adapta el outfit al clima: si hace frío (<15°C), incluye ropa exterior si está disponible.
4. La ocasión es prioritaria: un outfit de trabajo debe ser profesional aunque haga calor.
5. Desempate de prendas similares: prioriza las que tienen mayor coste_por_uso (CPW) para amortizarlas.

RESPONDE ÚNICAMENTE con este JSON exacto, sin texto adicional antes ni después:

{{
  "garment_ids": ["uuid-1", "uuid-2", "uuid-3"],
  "reasoning": "Explicación concisa en español de por qué esta combinación funciona para la ocasión y el clima.",
  "style_tip": "Un consejo de estilismo adicional (accesorio sugerido, forma de llevar la prenda, etc.)"
}}
"""


async def generate_outfit_suggestion(
    garments: list[Garment],
    weather: dict,
    occasion: str,
) -> dict:
    """
    Llama a la API de Groq y devuelve un dict con:
      - garment_ids: list[str]   → IDs de las prendas seleccionadas
      - reasoning:   str         → explicación del estilista
      - style_tip:   str         → consejo adicional

    Raises:
        HTTPException 422 si el LLM no devuelve JSON válido
        HTTPException 503 si Groq no responde
    """
    # Construir la lista de prendas para el prompt
    garments_data = [
        {
            "id": str(g.id),
            "nombre": g.name,
            "categoria": g.category,
            "color": g.color,
            "temporada": g.season,
            "ocasion_recomendada": g.occasion,
            "veces_usado": g.times_used,
            "coste_por_uso_eur": float(g.cost_per_wear) if g.cost_per_wear else 0.0,
        }
        for g in garments
    ]

    prompt = STYLIST_PROMPT.format(
        city=weather.get("city", ""),
        country=weather.get("country", ""),
        temp=weather.get("temp", ""),
        feels_like=weather.get("feels_like", ""),
        description=weather.get("description", ""),
        humidity=weather.get("humidity", ""),
        occasion=occasion,
        garments_json=json.dumps(garments_data, ensure_ascii=False, indent=2),
    )

    try:
        client = _get_client()
        completion = client.chat.completions.create(
            model=settings.GROQ_MODEL,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=600,
        )

        raw_response = completion.choices[0].message.content.strip()
        logger.info(f"Respuesta Groq recibida ({len(raw_response)} chars)")

        # Extraer JSON aunque el modelo añada texto antes/después
        suggestion = _parse_json_from_response(raw_response)

        # Validar que devolvió IDs que existen en el armario
        valid_ids = {str(g.id) for g in garments}
        suggestion["garment_ids"] = [
            gid for gid in suggestion.get("garment_ids", []) if gid in valid_ids
        ]

        if not suggestion["garment_ids"]:
            raise ValueError("El LLM no devolvió IDs de prendas válidos")

        return suggestion

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error en Groq API: {exc}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Error generando el outfit con IA: {exc}",
        )


def _parse_json_from_response(text: str) -> dict:
    """
    Intenta parsear JSON de la respuesta del LLM.
    Los modelos a veces añaden texto antes/después del JSON — lo manejamos con regex.
    """
    # Intento 1: respuesta ya es JSON limpio
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Intento 2: extraer el bloque JSON con regex
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass

    raise HTTPException(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        detail="La respuesta de la IA no tiene el formato esperado. Inténtalo de nuevo.",
    )
