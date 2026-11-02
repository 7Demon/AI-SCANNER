import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inspection_result.dart';

class GeminiService {
  static const String _prefKeyName = 'gemini_api_key';
  static const String _modelName = 'gemini-1.5-flash';
  static String? _cachedApiKey;

  /// Mengambil API Key dari .env, compile-time variable, atau SharedPreferences
  static Future<String?> getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey;
    }

    // 1. Baca langsung dari file .env di assets
    try {
      final envContent = await rootBundle.loadString('.env');
      for (final rawLine in envContent.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final separatorIdx = line.indexOf('=');
        if (separatorIdx != -1) {
          final key = line.substring(0, separatorIdx).trim();
          final val = line.substring(separatorIdx + 1).trim();
          if (key == 'GEMINI_API_KEY' &&
              val.isNotEmpty &&
              val != 'YOUR_GEMINI_API_KEY_HERE') {
            _cachedApiKey = val;
            return _cachedApiKey;
          }
        }
      }
    } catch (_) {
      // Abaikan jika berkas .env belum terbaca
    }

    // 2. Baca dari --dart-define=GEMINI_API_KEY=...
    const envDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envDefineKey.isNotEmpty) {
      _cachedApiKey = envDefineKey;
      return _cachedApiKey;
    }

    // 3. Fallback SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final prefKey = prefs.getString(_prefKeyName);
    if (prefKey != null && prefKey.isNotEmpty) {
      _cachedApiKey = prefKey;
      return _cachedApiKey;
    }

    return null;
  }

  /// Menguji validitas API Key
  static Future<bool> testApiKey(String apiKey) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=${apiKey.trim()}',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping test. Reply with OK.'}
              ]
            }
          ]
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Membandingkan Foto Sample vs Foto Aktual langsung via Gemini Vision API
  static Future<InspectionResult> compareSackPrinting({
    required String sampleBase64,
    required String actualBase64,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception(
        'Google Gemini API Key belum diisi. Buka file .env di root proyek lalu isi GEMINI_API_KEY=<kunci_api_anda>.',
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=${apiKey.trim()}',
    );

    const String systemPrompt = '''
Anda adalah auditor Quality Control (QC) ahli percetakan karung plastik/sak (woven bag / packaging sack).
Tugas Anda membandingkan:
- GAMBAR 1: Foto Karung Sample Standar (Master Proof)
- GAMBAR 2: Foto Hasil Cetak Aktual Mesin Produksi

Analisis secara teliti apakah cetakan aktual sudah mirip/sesuai standar atau belum.
Periksa 4 parameter kritis:
1. Akurasi Teks & Nomor: berat bersih (contoh Netto: 50kg), nomor izin/Kementan, nama merk, nomor batch, font, dan typo.
2. Kesesuaian Warna: apakah tinta pudar, meleset, salah campuran warna dibanding sample.
3. Presisi Posisi & Alignment: margin kiri-kanan, logo miring (skew), pergeseran gambar, atau terpotong jahitan karung.
4. Cacat Fisik Printing: noda/cipratan tinta (ink smudge/splatter), bagian botak/cetakan bolong (voids), garis tinta bocor.

Catatan penting:
- Abaikan lekukan atau lipatan fisik bahan karung dan bayangan pencahayaan ruangan, fokuslah murni pada grafis dan cetakan tinta.
- Nilai similarity_score dari 0 sampai 100.
  - Skor >= 85: status "PASS" (Mirip & Memenuhi Standar)
  - Skor 70 - 84: status "REVIEW" (Ada sedikit deviasi minor yang perlu dicek ulang)
  - Skor < 70: status "REJECT" (Tidak Mirip / Cacat Fatal)

Kembalikan HANYA dokumen JSON dengan struktur persis seperti ini:
{
  "similarity_score": 90,
  "status": "PASS",
  "is_match": true,
  "summary": "Ringkasan evaluasi komparasi cetak dalam 1-2 kalimat.",
  "analysis_details": {
    "text_accuracy": {
      "match": true,
      "notes": "Penjelasan detail teks..."
    },
    "color_fidelity": {
      "match": true,
      "notes": "Penjelasan detail warna..."
    },
    "alignment": {
      "match": true,
      "notes": "Penjelasan detail posisi/alignment..."
    },
    "defects_found": [
      "Deskripsi temuan cacat 1",
      "Deskripsi temuan cacat 2"
    ]
  },
  "recommendations": "Rekomendasi teknis untuk operator mesin cetak..."
}
''';

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': systemPrompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': sampleBase64,
              }
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': actualBase64,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.2,
      }
    };

    final http.Response response;
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 45));
    } catch (e) {
      throw Exception(
        'Gagal menghubungi server Gemini: Pastikan koneksi internet aktif. ($e)',
      );
    }

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw Exception(
          'Permintaan ditolak AI (400 Bad Request): Pastikan format gambar valid dan API Key benar.',
        );
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        throw Exception(
          'API Key tidak valid atau tidak memiliki izin akses (HTTP ${response.statusCode}). Silakan periksa kunci di file .env Anda.',
        );
      } else if (response.statusCode == 429) {
        throw Exception(
          'Batas kuota panggilan Gemini API tercapai (Rate Limit 429). Tunggu beberapa detik lalu coba lagi.',
        );
      } else {
        throw Exception(
          'Galat Gemini API (${response.statusCode}): ${response.body}',
        );
      }
    }

    try {
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final candidates = responseJson['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('AI tidak menghasilkan output (respons kosong).');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Konten analisis AI tidak ditemukan.');
      }

      String rawText = parts[0]['text']?.toString() ?? '';

      // Bersihkan jika model menyisipkan markdown ```json ... ```
      rawText = rawText.trim();
      if (rawText.startsWith('```json')) {
        rawText = rawText.substring(7);
      } else if (rawText.startsWith('```')) {
        rawText = rawText.substring(3);
      }
      if (rawText.endsWith('```')) {
        rawText = rawText.substring(0, rawText.length - 3);
      }
      rawText = rawText.trim();

      final Map<String, dynamic> parsedData = jsonDecode(rawText);
      return InspectionResult.fromJson(parsedData);
    } catch (e) {
      throw Exception('Gagal membaca data hasil analisis AI: $e');
    }
  }
}
