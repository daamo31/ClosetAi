import 'dart:convert';
import 'package:http/http.dart' as http;

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

  static String getWeatherIcon(String iconCode) {
    // Devuelve la URL del icono de OpenWeatherMap
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}
