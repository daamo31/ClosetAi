/// services/api_service.dart — Cliente HTTP para el backend ClosetAI
/// Gestiona autenticación, uploads y todas las llamadas a la API
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../models/garment.dart';
import '../models/outfit.dart';

class ApiException implements Exception {
  final String message;
  final int?   statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  /// Token JWT actual del usuario autenticado (Supabase Auth)
  String? get _token => Supabase.instance.client.auth.currentSession?.accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Manejo de errores ─────────────────────────────────────────────────────
  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['detail'] as String? ?? 'Error desconocido';
    } catch (_) {
      message = 'Error ${response.statusCode}';
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRENDAS
  // ══════════════════════════════════════════════════════════════════════════

  /// Sube una nueva prenda con foto al backend
  Future<Garment> uploadGarment({
    required File   imageFile,
    required String name,
    required String category,
    required String color,
    required String season,
    required String occasion,
    double purchasePrice = 0.0,
  }) async {
    if (_token == null) throw ApiException('No has iniciado sesión');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.uploadGarment),
    )
      ..headers['Authorization'] = 'Bearer $_token'
      ..fields['name']           = name
      ..fields['category']       = category
      ..fields['color']          = color
      ..fields['season']         = season
      ..fields['occasion']       = occasion
      ..fields['purchase_price'] = purchasePrice.toString();

    // Detectar tipo MIME por extensión
    final ext  = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png'
               : ext == 'webp' ? 'image/webp'
               : 'image/jpeg';

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType.parse(mime),
    ));

    try {
      final streamedResponse = await request.send().timeout(ApiConfig.uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      _checkResponse(response);
      return Garment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on Exception catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  /// Obtiene el armario completo del usuario
  Future<Map<String, dynamic>> listGarments({
    String? category,
    String? occasion,
  }) async {
    if (_token == null) throw ApiException('No has iniciado sesión');

    final uri = Uri.parse(ApiConfig.listGarments).replace(
      queryParameters: {
        if (category != null) 'category': category,
        if (occasion != null) 'occasion': occasion,
      },
    );

    final response = await http.get(uri, headers: _headers)
        .timeout(ApiConfig.defaultTimeout);
    _checkResponse(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'garments': (body['garments'] as List<dynamic>)
          .map((g) => Garment.fromJson(g as Map<String, dynamic>))
          .toList(),
      'total':        body['total'] as int,
      'can_add_more': body['can_add_more'] as bool,
      'free_limit':   body['free_limit'] as int,
    };
  }

  /// Elimina una prenda
  Future<void> deleteGarment(String garmentId) async {
    if (_token == null) throw ApiException('No has iniciado sesión');
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.listGarments}$garmentId'),
          headers: _headers,
        )
        .timeout(ApiConfig.defaultTimeout);
    _checkResponse(response);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OUTFITS
  // ══════════════════════════════════════════════════════════════════════════

  /// Genera un outfit del día con IA
  Future<Outfit> generateOutfit({
    required String city,
    required String occasion,
  }) async {
    if (_token == null) throw ApiException('No has iniciado sesión');

    final uri = Uri.parse(ApiConfig.generateOutfit).replace(
      queryParameters: {'city': city, 'occasion': occasion},
    );

    final response = await http.get(uri, headers: _headers)
        .timeout(ApiConfig.defaultTimeout);
    _checkResponse(response);
    return Outfit.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Historial de outfits generados
  Future<List<Outfit>> getOutfitHistory({int limit = 10}) async {
    if (_token == null) throw ApiException('No has iniciado sesión');

    final uri = Uri.parse(ApiConfig.outfitHistory)
        .replace(queryParameters: {'limit': limit.toString()});

    final response = await http.get(uri, headers: _headers)
        .timeout(ApiConfig.defaultTimeout);
    _checkResponse(response);

    return (jsonDecode(response.body) as List<dynamic>)
        .map((o) => Outfit.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USO / CPW
  // ══════════════════════════════════════════════════════════════════════════

  /// Registra el uso de una prenda → actualiza CPW
  Future<Map<String, dynamic>> logUsage({
    required String garmentId,
    String?  outfitId,
    String   occasion = 'casual',
  }) async {
    if (_token == null) throw ApiException('No has iniciado sesión');

    final response = await http.post(
      Uri.parse(ApiConfig.logUsage),
      headers: _headers,
      body: jsonEncode({
        'garment_id': garmentId,
        if (outfitId != null) 'outfit_id': outfitId,
        'occasion': occasion,
      }),
    ).timeout(ApiConfig.defaultTimeout);
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Registra el uso de TODAS las prendas de un outfit de golpe
  Future<Map<String, dynamic>> logOutfitUsage({
    required String outfitId,
    String occasion = 'casual',
  }) async {
    if (_token == null) throw ApiException('No has iniciado sesión');

    final response = await http.post(
      Uri.parse('${ApiConfig.logOutfit}/$outfitId')
          .replace(queryParameters: {'occasion': occasion}),
      headers: _headers,
    ).timeout(ApiConfig.defaultTimeout);
    _checkResponse(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEALTH
  // ══════════════════════════════════════════════════════════════════════════

  /// Verifica que el backend esté activo (wake-up call para Render)
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.health))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
