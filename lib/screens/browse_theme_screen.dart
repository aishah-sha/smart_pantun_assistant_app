import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/pantun_model.dart';
import '../services/pantun_service.dart';
import '../widgets/pantun_card.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BrowseThemeScreen extends StatefulWidget {
  const BrowseThemeScreen({super.key});

  @override
  State<BrowseThemeScreen> createState() => _BrowseThemeScreenState();
}

class _BrowseThemeScreenState extends State<BrowseThemeScreen> {
  String? _selectedTheme;
  List<Pantun> _pantunList = [];
  final FlutterTts _tts = FlutterTts();
  bool _loading = false;

  final themes = temaInfoMap.keys.toList();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ms-MY');
    _ensureDataLoaded();
  }

  // Fallback to guarantee data is fully initialized
  Future<void> _ensureDataLoaded() async {
    if (PantunService.instance.allPantun.isEmpty) {
      await PantunService.instance.loadData();
      if (mounted) {
        setState(() {}); // Rebuild to accurately update theme counter values
      }
    }
  }

  void _selectTheme(String tema) async {
    print('📱 Selecting theme: $tema');
    setState(() {
      _selectedTheme = tema;
      _loading = true;
    });

    if (PantunService.instance.allPantun.isEmpty) {
      print('📱 Loading data first...');
      await PantunService.instance.loadData();
      print(
        '📱 Data loaded, total pantuns: ${PantunService.instance.allPantun.length}',
      );
    }

    final list = PantunService.instance.getPantunByTheme(tema, limit: 30);
    print('📱 Found ${list.length} pantuns for theme $tema');

    if (mounted) {
      setState(() {
        _pantunList = list;
        _loading = false;
      });
    }
  }

  void _loadMore() async {
    if (_selectedTheme == null) return;
    setState(() => _loading = true);

    final more = PantunService.instance.getPantunByTheme(
      _selectedTheme!,
      limit: 30,
    );

    setState(() {
      _pantunList = more;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildThemeGrid(),
            const SizedBox(height: 8),
            Expanded(
              child: _selectedTheme == null
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        _buildThemeBanner(),
                        Expanded(child: _buildPantunList()),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semak Ikut Tema',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '6 tema pantun tradisional Melayu',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildThemeGrid() => SizedBox(
    height: 150,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: themes.length,
      itemBuilder: (ctx, i) {
        final tema = themes[i];
        final info = temaInfoMap[tema]!;
        final count = PantunService.instance.themeStats[tema] ?? 0;
        final selected = _selectedTheme == tema;
        return GestureDetector(
          onTap: () => _selectTheme(tema),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 140,
            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selected
                    ? [Color(info.warna), Color(info.warna).withOpacity(0.8)]
                    : [AppTheme.surface, AppTheme.surfaceElevated],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Colors.white.withOpacity(0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Color(info.warna).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(info.emoji, style: const TextStyle(fontSize: 28)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tema,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count pantun',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        color: selected
                            ? Colors.white.withOpacity(0.8)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _buildThemeBanner() {
    final info = temaInfoMap[_selectedTheme!]!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(info.warna).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(info.warna).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info.deskripsi,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppTheme.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _loadMore,
            style: TextButton.styleFrom(
              backgroundColor: Color(info.warna).withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Lain',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(
                  info.warna == 0xFFFFFFFF ? 0xFF818CF8 : info.warna,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPantunList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_pantunList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Tiada kandungan pantun ditemui.\nSila pastikan fail data asset tersedia.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _pantunList.length,
      itemBuilder: (ctx, i) {
        return PantunCard(
              pantun: _pantunList[i],
              onRead: () => _tts.speak(_pantunList[i].fullText),
            )
            .animate(delay: (i < 6 ? i * 50 : 0).ms)
            .slideY(begin: 0.05, curve: Curves.easeOutCubic)
            .fadeIn();
      },
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.category_outlined,
          size: 48,
          color: AppTheme.textSecondary.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Sila pilih tema di atas untuk melihat pantun',
          style: GoogleFonts.notoSans(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    ),
  ).animate().fadeIn();
}
