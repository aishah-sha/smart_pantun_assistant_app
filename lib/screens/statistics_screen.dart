import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/pantun_model.dart';
import '../services/pantun_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Map<String, int> _stats;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _stats = PantunService.instance.themeStats;
    _total = _stats.values.fold(0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildTotalCard()),
            SliverToBoxAdapter(
              child: _buildSectionTitle('Taburan Mengikut Tema'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final entry = _getSorted()[i];
                return _buildThemeBar(entry.key, entry.value, i);
              }, childCount: _stats.length),
            ),
            SliverToBoxAdapter(child: _buildSectionTitle('Maklumat Dataset')),
            SliverToBoxAdapter(child: _buildDatasetInfo()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  List<MapEntry<String, int>> _getSorted() =>
      _stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          'Analisis koleksi pantun',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _buildTotalCard() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.primary, Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withOpacity(0.4),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jumlah Pantun',
              style: GoogleFonts.notoSans(fontSize: 14, color: Colors.white70),
            ),
            Text(
              _total.toString(),
              style: GoogleFonts.playfairDisplay(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Sumber: Kurik Kundi Merah Saga',
              style: GoogleFonts.notoSans(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        const Spacer(),
        Column(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 56,
              color: Colors.white30,
            ),
            const SizedBox(height: 8),
            Text(
              '6 Tema',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    ),
  ).animate().scale(begin: const Offset(0.95, 0.95)).fadeIn(duration: 500.ms);

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
    child: Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  Widget _buildThemeBar(String tema, int count, int index) {
    final info = temaInfoMap[tema];
    final pct = _total > 0 ? count / _total : 0.0;
    final color = Color(info?.warna ?? 0xFF6366F1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(info?.emoji ?? '📜', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tema,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: Duration(milliseconds: 800 + index * 100),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(pct * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).slideX(begin: -0.05).fadeIn();
  }

  Widget _buildDatasetInfo() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        _infoRow('Sumber', 'Kurik Kundi Merah Saga'),
        _infoRow('Kaedah Klasifikasi', '6 Tema Baharu'),
        _infoRow('Bilangan Tema', '6'),
        _infoRow('Negeri', 'Pelbagai negeri di Malaysia'),
        _infoRow('Struktur', 'Pembayang (2 baris) + Isi (2 baris)'),
      ],
    ),
  );

  Widget _infoRow(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    ),
  );
}
