/// widgets/outfit_card.dart — Tarjeta del outfit del día
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/outfit.dart';
import '../theme/app_theme.dart';

class OutfitCard extends StatelessWidget {
  final Outfit outfit;
  final VoidCallback? onConfirmWorn;    // "Hoy lo llevo" → llama log-outfit

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onConfirmWorn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: clima + ocasión ──────────────────────────────────────
          _buildHeader(),

          // ── Grid de prendas ──────────────────────────────────────────────
          _buildGarmentsGrid(),

          // ── Razonamiento IA ──────────────────────────────────────────────
          if (outfit.reasoning.isNotEmpty) _buildReasoning(),

          // ── Consejo de estilo ────────────────────────────────────────────
          if (outfit.styleTip.isNotEmpty) _buildStyleTip(),

          // ── Botón confirmar uso ──────────────────────────────────────────
          if (onConfirmWorn != null) _buildConfirmButton(),

          const SizedBox(height: 4),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          // Ocasión
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              outfit.occasionLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Temperatura
          Row(
            children: [
              Image.network(
                outfit.weather.iconUrl,
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.wb_sunny_outlined, color: AppTheme.gold, size: 20),
              ),
              const SizedBox(width: 4),
              Text(
                outfit.weather.tempFormatted,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                outfit.weather.city,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Grid de prendas ────────────────────────────────────────────────────────
  Widget _buildGarmentsGrid() {
    final garments = outfit.garments;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: garments.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final g = garments[i];
            return Column(
              children: [
                // Imagen de la prenda
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: g.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: CachedNetworkImage(
                            imageUrl: g.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                g.categoryEmoji,
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            g.categoryEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                // Nombre truncado
                SizedBox(
                  width: 104,
                  child: Text(
                    g.name,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ).animate(delay: (i * 100).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
          },
        ),
      ),
    );
  }

  // ── Razonamiento IA ────────────────────────────────────────────────────────
  Widget _buildReasoning() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('✨ ', style: TextStyle(fontSize: 14)),
            Expanded(
              child: Text(
                outfit.reasoning,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Consejo de estilo ──────────────────────────────────────────────────────
  Widget _buildStyleTip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Text('💡 ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              outfit.styleTip,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón "Hoy lo llevo" ───────────────────────────────────────────────────
  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onConfirmWorn,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Hoy lo llevo · Registrar uso'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.success,
            side: const BorderSide(color: AppTheme.success),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
