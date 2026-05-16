import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../app_theme.dart';
import '../models/pantun_model.dart';
import '../services/pantun_service.dart';
import '../widgets/pantun_card.dart';
import '../widgets/theme_result_card.dart';

class VoiceClassifierScreen extends StatefulWidget {
  const VoiceClassifierScreen({super.key});

  @override
  State<VoiceClassifierScreen> createState() => _VoiceClassifierScreenState();
}

class _VoiceClassifierScreenState extends State<VoiceClassifierScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textCtrl = TextEditingController();

  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isClassifying = false;
  String _recognizedText = '';
  List<MapEntry<String, double>> _results = [];
  List<Pantun> _examplePantun = [];
  late AnimationController _pulseCtrl;

  // ── Confidence label thresholds ────────────────────────────────────────
  static const Map<String, String> _themeEmoji = {
    'Agama & Spiritual': '🕌',
    'Budi & Adab': '🙏',
    'Cinta & Kasih Sayang': '❤️',
    'Jenaka': '😄',
    'Nasihat & Moral': '📖',
    'Peribahasa & Kiasan': '🪞',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initSpeech();
    _tts.setLanguage('ms-MY');
    // Ensure pantun data is loaded
    PantunService.instance.loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech Error: $val'),
        onStatus: (val) => debugPrint('Speech Status: $val'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech Engine could not initialize: $e');
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    _textCtrl.clear();
    setState(() {
      _isListening = true;
      _recognizedText = '';
      _results = [];
      _examplePantun = [];
    });
    _pulseCtrl.repeat();

    await _speech.listen(
      onResult: (val) {
        setState(() {
          _recognizedText = val.recognizedWords;
          _textCtrl.text = _recognizedText;
        });
        if (val.finalResult) {
          _stopListening();
          _classify();
        }
      },
      localeId: 'ms_MY',
      // Classify incrementally so user sees live feedback
      partialResults: true,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    _pulseCtrl.reset();
    if (mounted) setState(() => _isListening = false);
  }

  void _classify() {
    final text = _textCtrl.text.trim().isEmpty
        ? _recognizedText.trim()
        : _textCtrl.text.trim();

    if (text.isEmpty) return;
    _recognizedText = text;

    setState(() => _isClassifying = true);
    final res = PantunService.instance.classifyText(text);

    setState(() {
      _results = res;
      _isClassifying = false;

      if (_results.isNotEmpty) {
        final topTheme = _results.first.key;
        final topScore = _results.first.value;
        _examplePantun = PantunService.instance.getPantunByTheme(
          topTheme,
          limit: 3,
        );

        // Announce in BM with confidence hint
        final confidenceWord = topScore >= 0.8
            ? 'sangat jelas'
            : topScore >= 0.5
                ? 'berpadanan'
                : 'mungkin';
        _tts.speak('Tema $confidenceWord: $topTheme');
      }
    });
  }

  // ── Confidence label ──────────────────────────────────────────────────
  String _confidenceLabel(double score) {
    if (score >= 0.85) return 'Sangat Tepat';
    if (score >= 0.65) return 'Tepat';
    if (score >= 0.40) return 'Sederhana';
    if (score >= 0.20) return 'Lemah';
    return 'Tidak Berpadanan';
  }

  Color _confidenceColor(double score) {
    if (score >= 0.85) return const Color(0xFF2E7D32); // deep green
    if (score >= 0.65) return const Color(0xFF558B2F); // light green
    if (score >= 0.40) return const Color(0xFFF57F17); // amber
    if (score >= 0.20) return const Color(0xFFBF360C); // orange-red
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Asisten Suara Pantun'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildMicSection()),
            SliverToBoxAdapter(child: _buildInputSection()),
            // Live interim classification while listening
            if (_isListening && _recognizedText.isNotEmpty)
              SliverToBoxAdapter(child: _buildLivePreview()),
            if (_isClassifying)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              ),
            if (!_isClassifying && _results.isNotEmpty) ...[
              SliverToBoxAdapter(child: _buildTopThemeBanner()),
              SliverToBoxAdapter(child: _buildResultsHeader()),
              SliverToBoxAdapter(child: _buildThemeResults()),
              if (_examplePantun.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildExamplesHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => PantunCard(
                      pantun: _examplePantun[i],
                      onRead: () => _tts.speak(_examplePantun[i].fullText),
                    ),
                    childCount: _examplePantun.length,
                  ),
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  // ── Mic button ───────────────────────────────────────────────────────
  Widget _buildMicSection() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 90 + (_pulseCtrl.value * 70),
              height: 90 + (_pulseCtrl.value * 70),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(1.0 - _pulseCtrl.value),
              ),
            ),
          ),
          // Mic button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppTheme.error : AppTheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? AppTheme.error : AppTheme.primary)
                        .withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Text input ───────────────────────────────────────────────────────
  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isListening ? 'Sila bercakap...' : 'Suara atau Teks Manual',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _textCtrl,
            maxLines: 3,
            onChanged: (val) => _recognizedText = val,
            decoration: InputDecoration(
              hintText:
                  'Sebut kata kunci atau taip pantun di sini untuk diklasifikasi...',
              hintStyle: GoogleFonts.notoSans(
                color: AppTheme.textSecondary.withOpacity(0.6),
                fontSize: 13,
              ),
              fillColor: AppTheme.surface,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryLight,
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _classify();
                },
              ),
            ),
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Live classification preview while listening ───────────────────────
  Widget _buildLivePreview() {
    final liveResults = PantunService.instance.classifyText(_recognizedText);
    if (liveResults.isEmpty) return const SizedBox.shrink();

    final top = liveResults.first;
    final emoji = _themeEmoji[top.key] ?? '🎵';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema dijangka: ${top.key}',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '"$_recognizedText"',
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.graphic_eq_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    )
        .animate(key: ValueKey(_recognizedText.length ~/ 3))
        .fadeIn(duration: 200.ms);
  }

  // ── Top theme banner ─────────────────────────────────────────────────
  Widget _buildTopThemeBanner() {
    final top = _results.first;
    final emoji = _themeEmoji[top.key] ?? '🎵';
    final label = _confidenceLabel(top.value);
    final color = _confidenceColor(top.value);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary.withOpacity(0.12),
              AppTheme.accent.withOpacity(0.07),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    top.key,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(top.value * 100).toStringAsFixed(0)}% padanan',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.2).fadeIn(duration: 400.ms);
  }

  // ── Results list header ──────────────────────────────────────────────
  Widget _buildResultsHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Text(
          'Semua Tema',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      );

  // ── Theme result bars ─────────────────────────────────────────────────
  Widget _buildThemeResults() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: _results.take(6).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final maxScore =
                _results.isNotEmpty ? _results.first.value : 1.0;
            return ThemeResultCard(
              tema: e.key,
              score: e.value,
              maxScore: maxScore,
              rank: i,
            ).animate(delay: (i * 80).ms).slideX(begin: -0.1).fadeIn();
          }).toList(),
        ),
      );

  // ── Example pantun header ─────────────────────────────────────────────
  Widget _buildExamplesHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 18,
              color: AppTheme.accent,
            ),
            const SizedBox(width: 8),
            Text(
              'Contoh Pantun Padanan',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
}
