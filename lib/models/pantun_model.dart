import 'package:flutter/material.dart';

class Pantun {
  final String baris1;
  final String baris2;
  final String baris3;
  final String baris4;
  final String negeri;
  final String tema;
  final String noBaru; // Add this for the "No. Baru" field

  const Pantun({
    required this.baris1,
    required this.baris2,
    required this.baris3,
    required this.baris4,
    required this.negeri,
    required this.tema,
    required this.noBaru,
    required String id,
  });

  factory Pantun.fromJson(Map<String, dynamic> json) {
    // Check if this is a header row or empty data
    final noBaru = json['field2'] as String? ?? '';

    // Skip header rows (where field2 contains text like "No. Baru" or "Jumlah Keseluruhan")
    if (noBaru.contains('No.') ||
        noBaru.contains('Jumlah') ||
        noBaru.isEmpty && (json['field3'] == null || json['field3'] == '')) {
      // Return a dummy invalid pantun that will be filtered out
      return Pantun._invalid();
    }

    return Pantun(
      baris1: (json['field3'] as String? ?? '').trim(),
      baris2: (json['field4'] as String? ?? '').trim(),
      baris3: (json['field5'] as String? ?? '').trim(),
      baris4: (json['field6'] as String? ?? '').trim(),
      negeri: (json['field7'] as String? ?? 'Umum').trim(),
      tema: (json['field8'] as String? ?? 'Nasihat & Moral').trim(),
      noBaru: noBaru,
      id: '',
    );
  }

  // Factory for creating an invalid pantun that will be filtered out
  factory Pantun._invalid() => Pantun(
    baris1: '',
    baris2: '',
    baris3: '',
    baris4: '',
    negeri: '',
    tema: '',
    noBaru: '',
    id: '',
  );

  bool get isValid =>
      baris1.isNotEmpty &&
      baris2.isNotEmpty &&
      baris3.isNotEmpty &&
      baris4.isNotEmpty;

  String get fullText => '$baris1\n$baris2\n$baris3\n$baris4';
  String get pembayang => '$baris1\n$baris2';
  String get isi => '$baris3\n$baris4';
}

// Keep your TemaInfo class the same
class TemaInfo {
  final String nama;
  final String emoji;
  final String deskripsi;
  final int warna;

  const TemaInfo({
    required this.nama,
    required this.emoji,
    required this.deskripsi,
    required this.warna,
  });
}

const Map<String, TemaInfo> temaInfoMap = {
  'Peribahasa & Kiasan': TemaInfo(
    nama: 'Peribahasa & Kiasan',
    emoji: '📜',
    deskripsi: 'Pantun bermakna dalam melalui perumpamaan dan kiasan',
    warna: 0xFF8B5CF6,
  ),
  'Agama & Spiritual': TemaInfo(
    nama: 'Agama & Spiritual',
    emoji: '🕌',
    deskripsi: 'Pantun berkaitan nilai keagamaan dan kerohanian',
    warna: 0xFF059669,
  ),
  'Budi & Adab': TemaInfo(
    nama: 'Budi & Adab',
    emoji: '🌸',
    deskripsi: 'Pantun menyentuh budi pekerti dan tata susila',
    warna: 0xFFF59E0B,
  ),
  'Cinta & Kasih Sayang': TemaInfo(
    nama: 'Cinta & Kasih Sayang',
    emoji: '💖',
    deskripsi: 'Pantun luahan rasa rindu, kasih, dan cinta sejati',
    warna: 0xFFEC4899,
  ),
  'Nasihat & Moral': TemaInfo(
    nama: 'Nasihat & Moral',
    emoji: '💡',
    deskripsi: 'Pantun pengajaran, moral, kepahlawanan, dan teladan hidup',
    warna: 0xFF3B82F6,
  ),
  'Jenaka': TemaInfo(
    nama: 'Jenaka',
    emoji: '😂',
    deskripsi: 'Pantun hiburan jenaka, santai, dan penuh keceriaan',
    warna: 0xFF10B981,
  ),
};
