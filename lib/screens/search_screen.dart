import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../app_theme.dart';
import '../models/pantun_model.dart';
import '../services/pantun_service.dart';
import '../widgets/pantun_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _tts = FlutterTts();
  List<Pantun> _results = [];
  bool _loading = false;
  Timer? _debounce;
  String _filterTheme = 'Semua';

  final _themes = ['Semua', ...temaInfoMap.keys];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ms-MY');
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  void _search(String q) {
    var r = PantunService.instance.searchPantun(q, limit: 50);
    if (_filterTheme != 'Semua')
      r = r.where((p) => p.tema == _filterTheme).toList();
    setState(() {
      _results = r;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
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
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Cari Pantun',
        style: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextField(
      controller: _ctrl,
      onChanged: _onChanged,
      style: GoogleFonts.notoSans(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.textSecondary,
        ),
        hintText: 'Cari baris pantun...',
        hintStyle: GoogleFonts.notoSans(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                onPressed: () {
                  _ctrl.clear();
                  setState(() => _results = []);
                },
              )
            : null,
      ),
    ),
  );

  Widget _buildFilterChips() => SizedBox(
    height: 52,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _themes.length,
      itemBuilder: (_, i) {
        final t = _themes[i];
        final sel = _filterTheme == t;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              t,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: sel ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            selected: sel,
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            onSelected: (_) {
              setState(() => _filterTheme = t);
              if (_ctrl.text.length >= 2) _search(_ctrl.text);
            },
          ),
        );
      },
    ),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (_ctrl.text.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Taip untuk mencari pantun',
              style: GoogleFonts.notoSans(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Daripada 5,644 pantun',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tiada pantun dijumpai',
              style: GoogleFonts.notoSans(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_results.length} keputusan',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _results.length,
            itemBuilder: (_, i) => PantunCard(
              pantun: _results[i],
              onRead: () => _tts.speak(_results[i].fullText),
              highlightQuery: _ctrl.text,
            ).animate(delay: (i * 30).ms).fadeIn(),
          ),
        ),
      ],
    );
  }
}
