"""
services/weather_service.py — Consulta el clima actual con OpenWeatherMap
API gratuita: 1.000 llamadas/día → más que suficiente para el MVP
"""
import logging
import httpx
from fastapi import HTTPException, status
from app.config import settings

logger = logging.getLogger(__name__)

OPENWEATHER_BASE_URL = "https://api.openweathermap.org/data/2.5/weather"


async def get_weather(city: str = None, lat: float = None, lon: float = None) -> dict:
    """
    Obtiene el clima actual de una ciudad o por coordenadas.

    Args:
        city: Nombre de la ciudad (ej: "Madrid", "Barcelona", "Zaragoza")
        lat: Latitud (alternativa a city)
        lon: Longitud (alternativa a city)

    Returns:
        dict con: city, temp, feels_like, description, humidity, icon
    """
    params = {
        "appid": settings.OPENWEATHER_API_KEY,
        "units": "metric",
        "lang": "es",
    }

    if lat is not None and lon is not None:
        params["lat"] = lat
        params["lon"] = lon
    elif city:
        params["q"] = city
    else:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Debes proporcionar una ciudad o coordenadas (lat/lon).",
        )

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(OPENWEATHER_BASE_URL, params=params)

            if response.status_code == 404:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Ciudad '{city}' no encontrada. Intenta con el nombre en inglés.",
                )
            if response.status_code == 401:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="API key de OpenWeatherMap inválida. Revisa las variables de entorno.",
                )

            response.raise_for_status()
            data = response.json()

        weather = {
            "city":        data["name"],
            "country":     data["sys"]["country"],
            "temp":        round(data["main"]["temp"], 1),
            "feels_like":  round(data["main"]["feels_like"], 1),
            "humidity":    data["main"]["humidity"],
            "description": data["weather"][0]["description"].capitalize(),
            "icon":        data["weather"][0]["icon"],   # ej: "01d" (sol)
        }

        logger.info(
            f"Clima obtenido para {weather['city']}: "
            f"{weather['temp']}°C, {weather['description']}"
        )
        return weather

    except HTTPException:
        raise
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="OpenWeatherMap no respondió a tiempo. Inténtalo más tarde.",
        )
    except Exception as exc:
        logger.error(f"Error consultando clima para '{city}': {exc}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Error obteniendo el clima: {exc}",
        )
