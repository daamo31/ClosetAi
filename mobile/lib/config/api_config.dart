/// api_config.dart — Configuración de la URL del backend
/// Cambia BASE_URL a la URL de Render.com cuando hagas el deploy
library;

class ApiConfig {
  ApiConfig._();

  // ── URL del Backend ────────────────────────────────────────────────────────
  // Durante desarrollo: usa la URL local si corres el backend en tu Mac
  // En producción:     reemplaza con tu URL de Render.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://closetai-backend.onrender.com', // ← cambia esto en Render
  );

  // ── Endpoints ──────────────────────────────────────────────────────────────
  static const String uploadGarment  = '$baseUrl/api/garments/upload';
  static const String listGarments   = '$baseUrl/api/garments/';
  static const String generateOutfit = '$baseUrl/api/outfits/generate';
  static const String outfitHistory  = '$baseUrl/api/outfits/history';
  static const String logUsage       = '$baseUrl/api/usage/log';
  static const String logOutfit      = '$baseUrl/api/usage/log-outfit';
  static const String health         = '$baseUrl/health';

  // ── Timeouts ──────────────────────────────────────────────────────────────
  // rembg tarda ~10-30s en la primera petición → timeout generoso
  static const Duration uploadTimeout  = Duration(seconds: 120);
  static const Duration defaultTimeout = Duration(seconds: 30);
}
