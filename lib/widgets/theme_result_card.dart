import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/pantun_model.dart';

class ThemeResultCard extends StatelessWidget {
  final String tema;
  final double score;
  final double maxScore;
  final int rank;

  const ThemeResultCard({
    super.key,
    required this.tema,
    required this.score,
    required this.maxScore,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final info = temaInfoMap[tema];

    // SAFEGUARDS: Safe fallbacks in case of character or whitespace anomalies in the dataset
    final color = Color(info?.warna ?? 0xFF4F46E5);
    final emoji = info?.emoji ?? '📜';
    final deskripsi =
        info?.deskripsi ?? 'Koleksi khazanah warisan puisi tradisional melayu.';

    final pct = maxScore > 0 ? score / maxScore : 0.0;
    final isTop = rank == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop ? color.withOpacity(0.15) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop ? color.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tema,
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                    color: isTop ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            deskripsi,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: Duration(milliseconds: 600 + rank * 100),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: val,
                backgroundColor: AppTheme.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
