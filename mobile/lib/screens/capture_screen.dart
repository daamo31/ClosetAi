/// screens/capture_screen.dart — Pantalla de captura de prenda
/// Permite hacer foto o elegir de galería, luego rellenar los datos y subir
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CaptureScreen extends StatefulWidget {
  final VoidCallback? onGarmentAdded;

  const CaptureScreen({super.key, this.onGarmentAdded});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _picker      = ImagePicker();

  // Imagen seleccionada
  File?  _imageFile;

  // Campos del formulario
  final _nameCtrl  = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _category = 'top';
  List<String> _seasonsSelected = ['all'];
  List<String> _occasionsSelected = ['casual'];
  bool   _loading  = false;

  // Opciones de select
  final _categories = [
    ('top',       '👕 Parte superior'),
    ('bottom',    '👖 Pantalón / Falda'),
    ('shoes',     '👟 Calzado'),
    ('outerwear', '🧥 Ropa exterior'),
    ('accessory', '💍 Accesorio'),
  ];

  final _seasons = [
    ('all',    '🌈 Todas las temporadas'),
    ('spring', '🌸 Primavera'),
    ('summer', '☀️ Verano'),
    ('autumn', '🍂 Otoño'),
    ('winter', '❄️ Invierno'),
  ];

  final _occasions = [
    ('casual', '😊 Casual'),
    ('work',   '💼 Trabajo'),
    ('sport',  '🏃 Deporte'),
    ('formal', '🎩 Formal'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source:       source,
        imageQuality: 85,
        maxWidth:     1200,
        maxHeight:    1200,
      );
      if (xFile != null) setState(() => _imageFile = File(xFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al acceder a la cámara/galería: $e')),
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📷 Primero toma o elige una foto'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await ApiService.instance.uploadGarment(
        imageFile:     _imageFile!,
        name:          _nameCtrl.text.trim(),
        category:      _category,
        color:         _colorCtrl.text.trim(),
        season:        _seasonsSelected.join(','),
        occasion:      _occasionsSelected.join(','),
        purchasePrice: double.tryParse(_priceCtrl.text) ?? 0.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ ¡Prenda añadida a tu armario!'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onGarmentAdded?.call();
        _reset();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() => _imageFile = null);
    _nameCtrl.clear();
    _colorCtrl.clear();
    _priceCtrl.clear();
    _category = 'top';
    _seasonsSelected = ['all'];
    _occasionsSelected = ['casual'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Añadir prenda'),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Zona de foto ──────────────────────────────────────────────
              _buildPhotoZone().animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              // ── Campos del formulario ─────────────────────────────────────
              _buildLabel('Nombre de la prenda *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ej: Camisa azul Oxford',
                  prefixIcon: Icon(Icons.label_outline, color: AppTheme.textMuted),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              _buildLabel('Color principal *'),
              const SizedBox(height: 8),
              TextFormField(
                controller:    _colorCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ej: Azul marino, Blanco roto',
                  prefixIcon: Icon(Icons.palette_outlined, color: AppTheme.textMuted),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              _buildLabel('Precio de compra (€)'),
              const SizedBox(height: 8),
              TextFormField(
                controller:   _priceCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Para calcular el coste por uso',
                  prefixIcon: Icon(Icons.euro_outlined, color: AppTheme.textMuted),
                  suffixText: '€',
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),
              _buildMultiSelectSection(),

              const SizedBox(height: 32),

              // ── Botón subir ───────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: _loading ? null : AppTheme.primaryGradient,
                  color:    _loading ? AppTheme.bgSurface : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _loading ? null : AppTheme.glowShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _upload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _loading
                        ? 'Subiendo y procesando imagen...'
                        : 'Añadir al armario',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor:     Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.transparent,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 8),

              const Text(
                '⏱ El fondo se eliminará automáticamente (puede tardar ~20 segundos)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Zona de foto ───────────────────────────────────────────────────────────
  Widget _buildPhotoZone() {
    return Column(
      children: [
        // Preview o placeholder
        GestureDetector(
          onTap: () => _showPickerDialog(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _imageFile != null ? AppTheme.primary : AppTheme.border,
                width: _imageFile != null ? 2 : 1,
              ),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.file(_imageFile!, fit: BoxFit.contain),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined,
                            color: AppTheme.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Añadir foto de la prenda',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'El fondo se eliminará automáticamente ✨',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Botones cámara / galería
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Cámara'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Galería'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Dropdowns ──────────────────────────────────────────────────────────────
  Widget _buildMultiSelectSection() {
    return Column(
      children: [
        _buildDropdown<String>(
          label: 'Categoría *',
          value: _category,
          items: _categories,
          onChanged: (v) => setState(() => _category = v!),
        ),
        const SizedBox(height: 14),
        _buildMultiSelectChips(
          label: 'Temporadas',
          options: _seasons,
          selected: _seasonsSelected,
          onChanged: (v) => setState(() => _seasonsSelected = v),
        ),
        const SizedBox(height: 14),
        _buildMultiSelectChips(
          label: 'Ocasiones',
          options: _occasions,
          selected: _occasionsSelected,
          onChanged: (v) => setState(() => _occasionsSelected = v),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildMultiSelectChips({
    required String label,
    required List<(String, String)> options,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((item) {
            final isSelected = selected.contains(item.$1);
            return FilterChip(
              label: Text(item.$2),
              selected: isSelected,
              onSelected: (val) {
                final newSelected = List<String>.from(selected);
                if (val) {
                  newSelected.add(item.$1);
                } else {
                  newSelected.remove(item.$1);
                }
                onChanged(newSelected);
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              backgroundColor: AppTheme.bgSurface,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<(T, String)> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          dropdownColor: AppTheme.bgCard,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: items.map((item) => DropdownMenuItem<T>(
            value: item.$1,
            child: Text(item.$2),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  Future<void> _showPickerDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              title: const Text('Usar la cámara', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
              title: const Text('Elegir de galería', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
