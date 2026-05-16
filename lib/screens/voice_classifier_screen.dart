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

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initSpeech();
    _tts.setLanguage('ms-MY');
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
    );
  }

  void _stopListening() async {
    await _speech.stop();
    _pulseCtrl.reset();
    if (mounted) setState(() => _isListening = false);
  }

  void _classify() {
    if (_recognizedText.trim().isEmpty) return;

    setState(() => _isClassifying = true);
    final res = PantunService.instance.classifyText(_recognizedText);

    setState(() {
      _results = res;
      _isClassifying = false;

      if (_results.isNotEmpty) {
        final topTheme = _results.first.key;
        _examplePantun = PantunService.instance.getPantunByTheme(
          topTheme,
          limit: 3,
        );
        _tts.speak('Tema dikesan: $topTheme');
      }
    });
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

  Widget _buildMicSection() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
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

  Widget _buildResultsHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
    child: Text(
      'Keputusan Klasifikasi',
      style: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    ),
  );

  Widget _buildThemeResults() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: _results.take(6).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final maxScore = _results.isNotEmpty ? _results.first.value : 1.0;
        return ThemeResultCard(
          tema: e.key,
          score: e.value,
          maxScore: maxScore,
          rank: i,
        ).animate(delay: (i * 80).ms).slideX(begin: -0.1).fadeIn();
      }).toList(),
    ),
  );

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
