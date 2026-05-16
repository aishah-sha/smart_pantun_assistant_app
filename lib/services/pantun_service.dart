import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pantun_model.dart';

class PantunService {
  static PantunService? _instance;
  static PantunService get instance => _instance ??= PantunService._();
  PantunService._();

  List<Pantun> _allPantun = [];
  bool _loaded = false;

  Future<void> loadData() async {
    if (_loaded) return;

    try {
      // Load the JSON file from assets
      final raw = await rootBundle.loadString('assets/pantun_data.json');
      final List<dynamic> list = json.decode(raw);

      _allPantun = [];

      for (var i = 0; i < list.length; i++) {
        final item = list[i] as Map<String, dynamic>;

        // Get the field values - these match your JSON structure
        final noBaru = item['field2']?.toString() ?? '';
        final baris1 = item['field3']?.toString() ?? '';
        final baris2 = item['field4']?.toString() ?? '';
        final baris3 = item['field5']?.toString() ?? '';
        final baris4 = item['field6']?.toString() ?? '';
        final negeri = item['field7']?.toString() ?? '';
        final tema = item['field8']?.toString() ?? '';

        // Skip header rows (first two entries in the JSON)
        // Header row 1: "Jumlah Keseluruhan: 5644 pantun"
        // Header row 2: "No. Baru", "No. Asal", etc.
        if (noBaru.contains('Jumlah') ||
            noBaru.contains('No.') ||
            (baris1.isEmpty &&
                baris2.isEmpty &&
                baris3.isEmpty &&
                baris4.isEmpty)) {
          continue;
        }

        // Only add if we have valid content
        if (baris1.isNotEmpty &&
            baris2.isNotEmpty &&
            baris3.isNotEmpty &&
            baris4.isNotEmpty) {
          _allPantun.add(
            Pantun(
              baris1: baris1.trim(),
              baris2: baris2.trim(),
              baris3: baris3.trim(),
              baris4: baris4.trim(),
              negeri: negeri.isNotEmpty ? negeri.trim() : 'Tidak diketahui',
              tema: tema.isNotEmpty ? tema.trim() : 'Nasihat & Moral',
              noBaru: '',
              id: '',
            ),
          );
        }
      }

      _loaded = true;
      debugPrint('✅ Berjaya memuatkan ${_allPantun.length} pantun');
    } catch (e) {
      debugPrint('❌ Error loading pantun data: $e');
      _allPantun = [];
      _loaded = true;
    }
  }

  List<Pantun> get allPantun => List.unmodifiable(_allPantun);
  bool get isLoaded => _loaded;

  // Get theme statistics
  Map<String, int> get themeStats {
    final stats = <String, int>{};
    for (final p in _allPantun) {
      stats[p.tema] = (stats[p.tema] ?? 0) + 1;
    }
    return stats;
  }

  // Get total number of pantuns
  int get totalPantuns => _allPantun.length;

  // Get pantuns by theme
  List<Pantun> getPantunByTheme(String tema, {int limit = 30}) {
    final filtered = _allPantun.where((p) => p.tema == tema).toList();
    if (filtered.isEmpty) return [];

    // Shuffle to get random results each time
    final shuffled = List<Pantun>.from(filtered);
    shuffled.shuffle(Random());
    return shuffled.take(limit).toList();
  }

  // Get first N pantuns by theme (not randomized)
  List<Pantun> getPantunByThemeOrdered(String tema, {int limit = 30}) {
    return _allPantun.where((p) => p.tema == tema).take(limit).toList();
  }

  // Search pantuns by keyword
  List<Pantun> searchPantun(String query, {int limit = 50}) {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    final words = lowerQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();

    if (words.isEmpty) return [];

    final results = <MapEntry<Pantun, int>>[];

    for (final p in _allPantun) {
      final fullText = p.fullText.toLowerCase();
      int score = 0;

      for (final word in words) {
        if (fullText.contains(word)) {
          score++;
        }
      }

      // Also check individual words in the query
      if (fullText.contains(lowerQuery)) {
        score += 3;
      }

      if (score > 0) {
        results.add(MapEntry(p, score));
      }
    }

    results.sort((a, b) => b.value.compareTo(a.value));
    return results.map((e) => e.key).take(limit).toList();
  }

  // Classify text to determine most likely theme
  List<MapEntry<String, double>> classifyText(String text) {
    if (text.trim().isEmpty) {
      return temaInfoMap.keys.map((k) => MapEntry(k, 0.0)).toList();
    }

    final lowerText = text.toLowerCase();
    final scores = <String, double>{};

    // Initialize scores for all themes
    for (final tema in temaInfoMap.keys) {
      scores[tema] = 0.0;
    }

    // Keywords for each theme
    final keywords = {
      'Peribahasa & Kiasan': [
        'umpama',
        'ibarat',
        'laksana',
        'bagai',
        'sindiran',
        'kiasan',
        'peribahasa',
        'tamsil',
        'misal',
        'contoh',
        'ibaratkan',
      ],
      'Agama & Spiritual': [
        'iman',
        'tuhan',
        'allah',
        'sembahyang',
        'solat',
        'dosa',
        'pahala',
        'syurga',
        'neraka',
        'nabi',
        'rasul',
        'zikir',
        'doa',
        'amal',
        'ibadat',
        'haji',
        'puasa',
        'ramadan',
        'islam',
        'mukmin',
      ],
      'Budi & Adab': [
        'budi',
        'adab',
        'jasa',
        'sopan',
        'santun',
        'kenang',
        'hormat',
        'adat',
        'pusaka',
        'tingkah',
        'laku',
        'pekerti',
        'akhlak',
        'tatasusila',
        'terima kasih',
        'tolong',
        'bantu',
      ],
      'Cinta & Kasih Sayang': [
        'cinta',
        'sayang',
        'kasih',
        'rindu',
        'hati',
        'kekasih',
        'adinda',
        'kekanda',
        'teruna',
        'dara',
        'buah hati',
        'jantung hati',
        'pujaan',
        'merindu',
        'berkasih',
        'bidadari',
        'tunang',
        'pinang',
      ],
      'Nasihat & Moral': [
        'nasihat',
        'pesan',
        'ingat',
        'ajaran',
        'belajar',
        'ilmu',
        'guru',
        'pahlawan',
        'berani',
        'kerja',
        'usaha',
        'rajin',
        'jimat',
        'hemat',
        'budi bahasa',
        'contoh',
        'teladan',
        'baik',
        'buruk',
      ],
      'Jenaka': [
        'jenaka',
        'lucu',
        'ketawa',
        'gelak',
        'gurau',
        'senda',
        'gila',
        'main',
        'lawak',
        'kelakar',
        'humor',
        'tertawa',
        'sungguhpun',
      ],
    };

    // Calculate scores based on keyword matches
    for (final entry in keywords.entries) {
      double themeScore = 0;
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          themeScore += 1.0;
        }
      }
      scores[entry.key] = themeScore;
    }

    // Rank the scores
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // If all scores are zero, give a small default to avoid division by zero
    final totalScore = ranked.fold(0.0, (sum, item) => sum + item.value);
    if (totalScore == 0.0) {
      // Return with minimal confidence for first theme
      return temaInfoMap.keys.toList().asMap().entries.map((e) {
        return MapEntry(e.value, e.key == 0 ? 0.01 : 0.0);
      }).toList();
    }

    return ranked;
  }

  // Get random pantuns
  List<Pantun> getRandomPantuns({int count = 10}) {
    if (_allPantun.isEmpty) return [];
    final shuffled = List<Pantun>.from(_allPantun);
    shuffled.shuffle(Random());
    return shuffled.take(count).toList();
  }

  // Get pantuns by state/negeri
  List<Pantun> getPantunByState(String negeri, {int limit = 20}) {
    final filtered = _allPantun
        .where((p) => p.negeri.contains(negeri))
        .toList();
    if (filtered.isEmpty) return [];
    filtered.shuffle(Random());
    return filtered.take(limit).toList();
  }

  // Get unique states/negeri list
  List<String> getUniqueStates() {
    final states = <String>{};
    for (final p in _allPantun) {
      if (p.negeri.isNotEmpty) {
        states.add(p.negeri);
      }
    }
    return states.toList()..sort();
  }

  // Get statistics about pantuns by state
  Map<String, int> getStateStats() {
    final stats = <String, int>{};
    for (final p in _allPantun) {
      stats[p.negeri] = (stats[p.negeri] ?? 0) + 1;
    }
    return stats;
  }
}
