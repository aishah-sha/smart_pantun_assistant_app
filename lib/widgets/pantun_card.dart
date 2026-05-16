import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/pantun_model.dart';

class PantunCard extends StatefulWidget {
  final Pantun pantun;
  final VoidCallback? onRead;
  final String? highlightQuery;

  const PantunCard({
    super.key,
    required this.pantun,
    this.onRead,
    this.highlightQuery,
  });

  @override
  State<PantunCard> createState() => _PantunCardState();
}

class _PantunCardState extends State<PantunCard> {
  bool _expanded = false;

  Color get _themeColor {
    final info = temaInfoMap[widget.pantun.tema];
    return info != null ? Color(info.warna) : AppTheme.primary;
  }

  String get _emoji => temaInfoMap[widget.pantun.tema]?.emoji ?? '📜';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? _themeColor.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: _themeColor.withOpacity(0.15),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            _buildPantunBody(),
            if (_expanded) _buildExpandedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPantunBody() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pembayang section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _themeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(color: _themeColor.withOpacity(0.5), width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembayang',
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  color: _themeColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              _buildLine(widget.pantun.baris1),
              _buildLine(widget.pantun.baris2),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Isi section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: AppTheme.textSecondary.withOpacity(0.3),
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isi',
                style: GoogleFonts.notoSans(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              _buildLine(widget.pantun.baris3),
              _buildLine(widget.pantun.baris4),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    widget.pantun.tema,
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: _themeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (widget.onRead != null)
              GestureDetector(
                onTap: widget.onRead,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildLine(String text) {
    if (widget.highlightQuery == null || widget.highlightQuery!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: GoogleFonts.notoSerif(
            fontSize: 14,
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
      );
    }
    final q = widget.highlightQuery!.toLowerCase();
    final lower = text.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(
        text,
        style: GoogleFonts.notoSerif(
          fontSize: 14,
          color: AppTheme.textPrimary,
          height: 1.5,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, idx),
            style: GoogleFonts.notoSerif(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: GoogleFonts.notoSerif(
              fontSize: 14,
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          TextSpan(
            text: text.substring(idx + q.length),
            style: GoogleFonts.notoSerif(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSection() => Container(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      children: [
        Divider(color: AppTheme.surfaceElevated),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              widget.pantun.negeri,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.pantun.fullText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Disalin ke papan keratan')),
                );
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Salin',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
