/// widgets/garment_tile.dart — Tarjeta de prenda para el armario
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/garment.dart';
import '../theme/app_theme.dart';

class GarmentTile extends StatelessWidget {
  final Garment garment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final int index;

  const GarmentTile({
    super.key,
    required this.garment,
    this.onTap,
    this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen ─────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // Fondo de imagen
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: garment.imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: garment.imageUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Text(
                                  garment.categoryEmoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              garment.categoryEmoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                  ),

                  // Badge CPW (si se ha usado)
                  if (garment.timesUsed > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: garment.isGoodCpw
                              ? AppTheme.success.withValues(alpha: 0.9)
                              : AppTheme.warning.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          garment.cpwFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Botón eliminar (con long press o si se pasa onDelete)
                  if (onDelete != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    garment.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Dot color
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _colorFromName(garment.color),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        garment.color,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Veces usado
                      Text(
                        '${garment.timesUsed}×',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms).scale(
            begin: const Offset(0.95, 0.95),
            curve: Curves.easeOut,
          ),
    );
  }

  /// Intenta mapear el nombre del color a un Color de Flutter
  Color _colorFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('negro') || n.contains('black')) return Colors.black87;
    if (n.contains('blanco') || n.contains('white')) return Colors.white;
    if (n.contains('azul') || n.contains('blue'))   return Colors.blue;
    if (n.contains('rojo') || n.contains('red'))    return Colors.red;
    if (n.contains('verde') || n.contains('green')) return Colors.green;
    if (n.contains('gris') || n.contains('grey') || n.contains('gray')) return Colors.grey;
    if (n.contains('amarillo') || n.contains('yellow')) return Colors.yellow;
    if (n.contains('rosa') || n.contains('pink'))   return Colors.pink;
    if (n.contains('naranja') || n.contains('orange')) return Colors.orange;
    if (n.contains('morado') || n.contains('violeta') || n.contains('purple')) return Colors.purple;
    if (n.contains('marron') || n.contains('marrón') || n.contains('brown')) return Colors.brown;
    if (n.contains('beige') || n.contains('crema')) return const Color(0xFFF5DEB3);
    return AppTheme.primary;  // fallback
  }
}
