import 'dart:convert';
import 'dart:math';
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
      final raw = await rootBundle.loadString('assets/pantun_data.json');
      final list = json.decode(raw) as List;

      print('📊 Raw JSON entries: ${list.length}');

      _allPantun = list
          .where((e) => e is Map<String, dynamic>)
          .map((e) => Pantun.fromJson(e as Map<String, dynamic>))
          .where((pantun) => pantun.isValid)
          .toList();

      _loaded = true;
      print('✅ Loaded ${_allPantun.length} valid pantuns');

      // Print theme distribution for debugging
      final stats = themeStats;
      stats.forEach((theme, count) {
        print('   $theme: $count pantuns');
      });
    } catch (e) {
      print('❌ Error loading pantun data: $e');
      rethrow;
    }
  }

  List<Pantun> get allPantun => List.unmodifiable(_allPantun);

  Map<String, int> get themeStats {
    final stats = <String, int>{};
    for (final p in _allPantun) {
      stats[p.tema] = (stats[p.tema] ?? 0) + 1;
    }
    return stats;
  }

  // Rest of your methods remain the same...
  List<MapEntry<String, double>> classifyText(String text) {
    // ... your existing code ...
    if (text.trim().isEmpty) {
      return temaInfoMap.keys.map((k) => MapEntry(k, 0.0)).toList();
    }

    final lower = text.toLowerCase();
    final scores = <String, double>{};
    for (final t in temaInfoMap.keys) {
      scores[t] = 0.0;
    }

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
      ],
      'Agama & Spiritual': [
        'iman',
        'tuhan',
        'sembahyang',
        'dosa',
        'pahala',
        'syurga',
        'neraka',
        'solat',
        'nabi',
        'zikir',
        'amal',
      ],
      'Budi & Adab': [
        'budi',
        'adab',
        'jasa',
        'sopan',
        'santun',
        'kenang',
        'terima kasih',
        'hormat',
        'adat',
        'pusaka',
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
      ],
      'Nasihat & Moral': [
        'nasihat',
        'ingat',
        'pakai',
        'belajar',
        'guru',
        'ilmu',
        'pahlawan',
        'rantau',
        'niaga',
        'kerja',
        'moral',
      ],
      'Jenaka': [
        'jenaka',
        'lucu',
        'ketawa',
        'gelak',
        'gurau',
        'senda',
        'gila',
        'terbahak',
        'lelucon',
      ],
    };

    for (final entry in keywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          scores[entry.key] = (scores[entry.key] ?? 0) + 1.0;
        }
      }
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    double totalScore = ranked.fold(0, (sum, item) => sum + item.value);
    if (totalScore == 0.0) {
      return temaInfoMap.keys.toList().asMap().entries.map((e) {
        return MapEntry(e.value, e.key == 0 ? 0.01 : 0.0);
      }).toList();
    }

    return ranked;
  }

  List<Pantun> getPantunByTheme(String tema, {int limit = 20}) {
    final filtered = _allPantun.where((p) => p.tema == tema).toList();
    if (filtered.isEmpty) return [];
    filtered.shuffle(Random());
    return filtered.take(limit).toList();
  }

  List<Pantun> searchPantun(String query, {int limit = 30}) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    final words = lower
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
    if (words.isEmpty) return [];

    final results = <MapEntry<Pantun, int>>[];
    for (final p in _allPantun) {
      final text = p.fullText.toLowerCase();
      int score = 0;
      for (final w in words) {
        if (text.contains(w)) score++;
      }
      if (score > 0) results.add(MapEntry(p, score));
    }
    results.sort((a, b) => b.value.compareTo(a.value));
    return results.map((e) => e.key).take(limit).toList();
  }
}
