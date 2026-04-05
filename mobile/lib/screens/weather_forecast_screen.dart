import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

class WeatherForecastScreen extends StatefulWidget {
  final String city;
  const WeatherForecastScreen({super.key, required this.city});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  List<Map<String, dynamic>>? _forecast;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await WeatherService.getTodayForecast(widget.city);
      setState(() { _forecast = data; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Error al cargar la previsión.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Previsión en ${widget.city}'),
        backgroundColor: AppTheme.bgDark,
      ),
      backgroundColor: AppTheme.bgDark,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
              : _forecast == null || _forecast!.isEmpty
                  ? const Center(child: Text('Sin datos de previsión para hoy', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _forecast!.length,
                      separatorBuilder: (_, __) => const Divider(color: AppTheme.border),
                      itemBuilder: (context, i) {
                        final item = _forecast![i];
                        final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
                        final temp = item['main']['temp'];
                        final desc = item['weather'][0]['description'];
                        final icon = item['weather'][0]['icon'];
                        final hour = '${dt.hour.toString().padLeft(2, '0')}:00';
                        return Row(
                          children: [
                            Image.network(WeatherService.getWeatherIcon(icon), width: 40, height: 40),
                            const SizedBox(width: 16),
                            Text(hour, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
                            const SizedBox(width: 16),
                            Text('${temp.round()}°C', style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Expanded(child: Text(desc, style: const TextStyle(color: AppTheme.textSecondary))),
                          ],
                        );
                      },
                    ),
    );
  }
}
