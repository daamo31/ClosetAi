import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
    static const _forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

    static Future<List<Map<String, dynamic>>?> getTodayForecast(String city) async {
      final url = Uri.parse('$_forecastUrl?q=$city&units=metric&lang=es&appid=$_apiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final now = DateTime.now();
        final today = data['list'].where((item) {
          final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          return dt.day == now.day && dt.month == now.month && dt.year == now.year;
        }).toList();
        return List<Map<String, dynamic>>.from(today);
      }
      return null;
    }

    static Future<List<Map<String, dynamic>>?> getTodayForecastByCoords(double lat, double lon) async {
      final url = Uri.parse('$_forecastUrl?lat=$lat&lon=$lon&units=metric&lang=es&appid=$_apiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final now = DateTime.now();
        final today = data['list'].where((item) {
          final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          return dt.day == now.day && dt.month == now.month && dt.year == now.year;
        }).toList();
        return List<Map<String, dynamic>>.from(today);
      }
      return null;
    }

  static const _apiKey = '6aa3e6be8b4e582883abfa71e4127866';
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  static Future<Map<String, dynamic>?> getCurrentWeather(String city) async {
    final url = Uri.parse('$_baseUrl?q=$city&units=metric&lang=es&appid=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getCurrentWeatherByCoords(double lat, double lon) async {
    final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&units=metric&lang=es&appid=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  /// Obtiene la posición actual del dispositivo
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  }

  /// Obtiene el nombre de la ciudad a partir de coordenadas
  static Future<String?> getCityFromCoords(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
      }
    } catch (_) {}
    return null;
  }

  static String getWeatherIcon(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}
