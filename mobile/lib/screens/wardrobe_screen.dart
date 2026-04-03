/// screens/wardrobe_screen.dart — Pantalla del armario completo
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/garment.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/garment_tile.dart';

class WardrobeScreen extends StatefulWidget {
  final VoidCallback? onAddGarment;    // navega a CaptureScreen

  const WardrobeScreen({super.key, this.onAddGarment});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<Garment> _garments    = [];
  bool          _loading     = true;
  bool          _canAddMore  = true;
  int           _total       = 0;
  String?       _categoryFilter;
  bool          _editMode    = false;

  final _categories = [
    (null,          '🧺 Todos'),
    ('top',         '👕 Tops'),
    ('bottom',      '👖 Pantalones'),
    ('shoes',       '👟 Calzado'),
    ('outerwear',   '🧥 Exterior'),
    ('accessory',   '💍 Accesorios'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listGarments(
        category: _categoryFilter,
      );
      setState(() {
        _garments   = data['garments'] as List<Garment>;
        _total      = data['total'] as int;
        _canAddMore = data['can_add_more'] as bool;
      });
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

  Future<void> _deleteGarment(Garment g) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Eliminar prenda', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '¿Eliminar "${g.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.instance.deleteGarment(g.id);
        await _load();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mi Armario',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$_total prenda${_total != 1 ? "s" : ""} · '
                        '${30 - _total > 0 && _canAddMore ? "${30 - _total} libres" : "Premium"}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Edit mode toggle
                  IconButton(
                    onPressed: () => setState(() => _editMode = !_editMode),
                    icon: Icon(
                      _editMode ? Icons.check : Icons.edit_outlined,
                      color: _editMode ? AppTheme.success : AppTheme.textMuted,
                    ),
                  ),
                  // Barra de progreso freemium
                  if (!_canAddMore)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✨ Premium',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),

            // ── Barra de progreso ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProgressBar(),
            ),

            const SizedBox(height: 12),

            // ── Filtros de categoría ──────────────────────────────────────
            _buildCategoryFilter(),

            const SizedBox(height: 12),

            // ── Grid ──────────────────────────────────────────────────────
            Expanded(child: _loading ? _buildShimmer() : _buildGrid()),
          ],
        ),
      ),

      // ── FAB añadir prenda ─────────────────────────────────────────────
      floatingActionButton: _canAddMore
          ? FloatingActionButton.extended(
              onPressed: widget.onAddGarment,
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
              label: const Text('Añadir', style: TextStyle(color: Colors.white)),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Actualiza a Premium para añadir más prendas ✨'),
                    backgroundColor: AppTheme.primary,
                  ),
                );
              },
              backgroundColor: AppTheme.bgSurface2,
              icon: const Icon(Icons.lock_outline, color: AppTheme.textMuted),
              label: const Text('Límite alcanzado', style: TextStyle(color: AppTheme.textMuted)),
            ),
    );
  }

  Widget _buildProgressBar() {
    final pct = (_total / 30).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppTheme.bgSurface2,
            valueColor: AlwaysStoppedAnimation(
              pct >= 1.0 ? AppTheme.error : AppTheme.primary,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_total / 30 prendas (plan gratuito)',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _categoryFilter == cat.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _categoryFilter = cat.$1);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: sel ? AppTheme.primaryGradient : null,
                color:    sel ? null : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? Colors.transparent : AppTheme.border),
              ),
              child: Text(
                cat.$2,
                style: TextStyle(
                  color: sel ? Colors.white : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    if (_garments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👗', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text(
              'Tu armario está vacío',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Pulsa el botón + para añadir\ntu primera prenda',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      backgroundColor: AppTheme.bgCard,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _garments.length,
        itemBuilder: (_, i) => GarmentTile(
          garment: _garments[i],
          index: i,
          onDelete: _editMode ? () => _deleteGarment(_garments[i]) : null,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.bgSurface,
        highlightColor: AppTheme.bgSurface2,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
