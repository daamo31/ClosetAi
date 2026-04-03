/// models/outfit.dart — Modelo de outfit generado por IA
library;

import 'garment.dart';

class WeatherInfo {
  final String city;
  final String country;
  final double temp;
  final double feelsLike;
  final String description;
  final int    humidity;
  final String icon;

  const WeatherInfo({
    required this.city,
    required this.country,
    required this.temp,
    required this.feelsLike,
    required this.description,
    required this.humidity,
    required this.icon,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) => WeatherInfo(
        city:        json['city'] as String? ?? '',
        country:     json['country'] as String? ?? '',
        temp:        (json['temp'] as num?)?.toDouble() ?? 0,
        feelsLike:   (json['feels_like'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '',
        humidity:    json['humidity'] as int? ?? 0,
        icon:        json['icon'] as String? ?? '01d',
      );

  /// URL del icono de clima de OpenWeatherMap
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  /// Temperatura formateada
  String get tempFormatted => '${temp.round()}°C';
}

class Outfit {
  final String      id;
  final String      occasion;
  final List<Garment> garments;
  final String      reasoning;
  final String      styleTip;
  final WeatherInfo weather;
  final DateTime?   createdAt;

  const Outfit({
    required this.id,
    required this.occasion,
    required this.garments,
    required this.reasoning,
    required this.styleTip,
    required this.weather,
    this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id:       json['id'] as String,
        occasion: json['occasion'] as String,
        garments: (json['garments'] as List<dynamic>)
            .map((g) => Garment.fromJson(g as Map<String, dynamic>))
            .toList(),
        reasoning: json['reasoning'] as String? ?? '',
        styleTip:  json['style_tip'] as String? ?? '',
        weather:   WeatherInfo.fromJson(json['weather'] as Map<String, dynamic>),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  /// Etiqueta de ocasión en español
  String get occasionLabel => switch (occasion) {
        'work'    => '💼 Trabajo',
        'casual'  => '😊 Casual',
        'sport'   => '🏃 Deporte',
        'formal'  => '🎩 Formal',
        'dinner'  => '🍷 Cena',
        _         => occasion,
      };
}
