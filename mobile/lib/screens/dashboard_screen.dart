/// screens/dashboard_screen.dart — Pantalla principal
/// Muestra el outfit del día, clima y estadísticas del armario
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/outfit.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/outfit_card.dart';
import '../services/weather_service.dart';
import 'weather_forecast_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
    Map<String, dynamic>? _weather;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _fetchWeather();
  }

    Future<void> _fetchWeather() async {
      Map<String, dynamic>? data;
      if (_usingGps && _lat != null && _lon != null) {
        data = await WeatherService.getCurrentWeatherByCoords(_lat!, _lon!);
      } else {
        data = await WeatherService.getCurrentWeather(_city);
      }
      if (mounted && data != null) {
        setState(() => _weather = data);
      }
    }
  Outfit? _outfit;
  bool    _loading    = false;
  bool    _confirming = false;
  String  _error      = '';

  // Configuración del usuario
  String   _city     = 'Madrid';
  String   _occasion = 'casual';
  bool     _usingGps = false;
  double?  _lat;
  double?  _lon;

  final _occasions = [
    ('casual',  '😊 Casual'),
    ('work',    '💼 Trabajo'),
    ('sport',   '🏃 Deporte'),
    ('formal',  '🎩 Formal'),
    ('dinner',  '🍷 Cena'),
  ];


  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _city     = prefs.getString('city')     ?? 'Madrid';
      _occasion = prefs.getString('occasion') ?? 'casual';
      _usingGps = prefs.getBool('usingGps')   ?? false;
    });
    // Intentar geolocalización automática
    if (_usingGps) {
      await _detectLocation();
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', _city);
    await prefs.setString('occasion', _occasion);
    await prefs.setBool('usingGps', _usingGps);
  }

  Future<void> _detectLocation() async {
    final position = await WeatherService.getCurrentPosition();
    if (position != null) {
      _lat = position.latitude;
      _lon = position.longitude;
      final cityName = await WeatherService.getCityFromCoords(_lat!, _lon!);
      if (cityName != null && mounted) {
        setState(() {
          _city = cityName;
          _usingGps = true;
        });
        _savePrefs();
        _fetchWeather();
      }
    }
  }

  Future<void> _generateOutfit() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final outfit = await ApiService.instance.generateOutfit(
        city:     _city,
        occasion: _occasion,
      );
      setState(() => _outfit = outfit);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmWorn() async {
    if (_outfit == null) return;
    setState(() => _confirming = true);
    try {
      await ApiService.instance.logOutfitUsage(
        outfitId: _outfit!.id,
        occasion: _outfit!.occasion,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Uso registrado! Tu CPW se ha actualizado.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  String get _userName {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ─────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildAppBar()),

            // ── Config strip ───────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildConfigStrip()),

            // ── Contenido ──────────────────────────────────────────────────
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar custom ──────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $_userName 👋',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tu outfit de hoy',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 22),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  // ── Strip de ciudad + ocasión ──────────────────────────────────────────────
  Widget _buildConfigStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Ciudad y clima
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppTheme.textMuted, size: 16),
              if (_usingGps) const Icon(Icons.gps_fixed, color: AppTheme.primary, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: _showCityDialog,
                  child: Text(
                    _city,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (_weather != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeatherForecastScreen(city: _city),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      if (_weather!['weather'] != null && _weather!['weather'][0]['icon'] != null)
                        Image.network(
                          WeatherService.getWeatherIcon(_weather!['weather'][0]['icon']),
                          width: 28, height: 28,
                        ),
                      const SizedBox(width: 4),
                      if (_weather!['main'] != null && _weather!['main']['temp'] != null)
                        Text(
                          '${_weather!['main']['temp'].round()}°C',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(width: 12),
              const Icon(Icons.edit_outlined, color: AppTheme.textMuted, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          // Ocasión chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _occasions.map((item) {
                final isSelected = _occasion == item.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _occasion = item.$1);
                      _savePrefs();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.primaryGradient : null,
                        color: isSelected ? null : AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        item.$2,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cuerpo principal ───────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error.isNotEmpty) return _buildError();
    if (_outfit == null) return _buildEmpty();
    return _buildOutfit();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.glowShadow,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1500.ms,
                color: Colors.white.withValues(alpha: 0.3),
              ),
          const SizedBox(height: 20),
          const Text(
            'La IA está eligiendo\ntu outfit perfecto...',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consultando el clima y tu armario',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateOutfit,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text('🧥', style: TextStyle(fontSize: 56)),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(),

          const SizedBox(height: 24),

          const Text(
            '¿Qué te pongo hoy?',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          const Text(
            'Pulsa el botón y la IA mirará el clima\ny tu armario para sugerirte el outfit perfecto',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 32),

          // Botón generar
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.glowShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: _generateOutfit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar outfit del día', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor:     Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildOutfit() {
    return Column(
      children: [
        OutfitCard(
          outfit: _outfit!,
          onConfirmWorn: _confirming ? null : _confirmWorn,
        ),
        const SizedBox(height: 16),
        // Generar otro outfit
        OutlinedButton.icon(
          onPressed: _generateOutfit,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Generar otro outfit'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.border),
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Dialog de ciudad ───────────────────────────────────────────────────────
  Future<void> _showCityDialog() async {
    final ctrl = TextEditingController(text: _city);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Tu ciudad', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ej: Madrid, Barcelona...',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _usingGps = true);
                await _detectLocation();
                _fetchWeather();
              },
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Usar mi ubicación (GPS)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _city = ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : _city;
                _usingGps = false;
                _lat = null;
                _lon = null;
              });
              _savePrefs();
              _fetchWeather();
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
