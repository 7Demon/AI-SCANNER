import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inspection_result.dart';

class ApiKeyTestResult {
  final bool isValid;
  final String message;

  const ApiKeyTestResult({
    required this.isValid,
    required this.message,
  });
}

class GeminiService {
  static const String _prefCustomKeyName = 'gemini_custom_api_key';
  static const String _prefModelKey = 'gemini_active_model';
  static const String defaultModel = 'gemini-3.1-flash-lite';

  /// Daftar model yang didukung dan siap dipilih pengguna
  static const List<Map<String, String>> supportedModels = [
    {
      'id': 'gemini-3.1-flash-lite',
      'name': 'Gemini 3.1 Flash Lite (Rekomendasi Utama)',
      'description':
          'Model super cepat, sangat responsif, dan stabil untuk analisis cetak karung. Kuota: 15 RPM / 500 RPD.',
    },
    {
      'id': 'gemini-3.5-flash-lite',
      'name': 'Gemini 3.5 Flash Lite (Generasi Baru)',
      'description':
          'Model Flash Lite generasi 3.5 dengan pemahaman visual lebih cerdas. Kuota: 15 RPM / 500 RPD.',
    },
    {
      'id': 'gemini-3.8-flash',
      'name': 'Gemini 3.8 Flash',
      'description':
          'Model Flash versi 3.8 dengan kemampuan penalaran multimodal tingkat lanjut.',
    },
    {
      'id': 'gemini-3-flash-preview',
      'name': 'Gemini 3 Flash Preview',
      'description':
          'Versi preview Gemini 3 Flash dengan akurasi pengenalan pola tinggi.',
    },
    {
      'id': 'gemini-3.1-pro-preview',
      'name': 'Gemini 3.1 Pro Preview',
      'description':
          'Model kelas Pro untuk analisis teks mikro dan detail rumit.',
    },
  ];
  
  // Fallback default key jika .env belum terisi
  static const String _fallbackDefaultKey = 'YOUR_GEMINI_API_KEY_HERE';

  static String? _cachedActiveApiKey;

  /// Mengambil model aktif yang sedang dipilih (default: gemini-3.1-flash-lite)
  static Future<String> getActiveModel() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefModelKey);
    // Jika masih menyimpan model usang (seperti 1.5 atau 2.5-flash) yang sudah tidak didukung Google,
    // migrasikan otomatis ke defaultModel (gemini-3.1-flash-lite)
    if (saved != null &&
        saved.isNotEmpty &&
        !saved.contains('1.5') &&
        !saved.contains('2.5-flash') &&
        supportedModels.any((m) => m['id'] == saved)) {
      return saved;
    }
    return defaultModel;
  }

  /// Mengubah model yang digunakan
  static Future<void> setActiveModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefModelKey, modelId);
  }

  /// Mengambil kunci kustom yang dimasukkan pengguna (jika ada)
  static Future<String?> getCustomApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString(_prefCustomKeyName)?.trim();
    if (customKey != null && customKey.isNotEmpty) {
      return customKey;
    }
    return null;
  }

  /// Mengambil kunci default (dari .env, compile-time variable, atau fallback bawaan)
  static Future<String> getDefaultApiKey() async {
    // 1. Cek dari .env di assets
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
            return val;
          }
        }
      }
    } catch (_) {
      // Abaikan jika .env belum terload
    }

    // 2. Cek dari --dart-define=GEMINI_API_KEY=...
    const envDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envDefineKey.isNotEmpty && envDefineKey != 'YOUR_GEMINI_API_KEY_HERE') {
      return envDefineKey;
    }

    return _fallbackDefaultKey;
  }

  /// Mengecek apakah aplikasi saat ini menggunakan kunci kustom pengguna
  static Future<bool> isUsingCustomKey() async {
    final customKey = await getCustomApiKey();
    return customKey != null && customKey.isNotEmpty;
  }

  /// Mengambil API Key yang aktif: Kunci Kustom (Prioritas 1) atau Kunci Default (Prioritas 2)
  static Future<String?> getActiveApiKey() async {
    if (_cachedActiveApiKey != null && _cachedActiveApiKey!.isNotEmpty) {
      return _cachedActiveApiKey;
    }

    // Prioritas 1: Kunci Kustom dari Pengguna
    final customKey = await getCustomApiKey();
    if (customKey != null && customKey.isNotEmpty) {
      _cachedActiveApiKey = customKey;
      return _cachedActiveApiKey;
    }

    // Prioritas 2: Kunci Default Sistem
    final defaultKey = await getDefaultApiKey();
    if (defaultKey.isNotEmpty && defaultKey != 'YOUR_GEMINI_API_KEY_HERE') {
      _cachedActiveApiKey = defaultKey;
      return _cachedActiveApiKey;
    }

    return null;
  }

  /// Menguji validitas sebuah API Key ke Google Gemini sebelum digunakan
  static Future<ApiKeyTestResult> testApiKey(String apiKey, {String? model}) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty || cleanKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return const ApiKeyTestResult(
        isValid: false,
        message: 'API Key tidak boleh kosong atau berupa placeholder.',
      );
    }

    try {
      final modelToUse = model ?? await getActiveModel();
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelToUse:generateContent?key=$cleanKey',
      );

      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return const ApiKeyTestResult(
          isValid: true,
          message: 'Koneksi Berhasil! API Key valid dan aktif di Google Gemini.',
        );
      } else if (response.statusCode == 400) {
        return const ApiKeyTestResult(
          isValid: false,
          message:
              'API Key tidak valid (400 Bad Request). Pastikan kunci disalin dengan benar.',
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiKeyTestResult(
          isValid: false,
          message:
              'Izin ditolak (HTTP ${response.statusCode}). API Key salah atau dinonaktifkan di Google AI Studio.',
        );
      } else if (response.statusCode == 404) {
        return ApiKeyTestResult(
          isValid: false,
          message:
              'Model "$modelToUse" tidak ditemukan (HTTP 404). Gunakan model Gemini 3.1 Flash Lite.',
        );
      } else if (response.statusCode == 429) {
        return const ApiKeyTestResult(
          isValid: false,
          message:
              'Batas kuota API tercapai (Rate Limit 429). Coba gunakan kunci lain atau tunggu sesaat.',
        );
      } else {
        return ApiKeyTestResult(
          isValid: false,
          message: 'Gagal verifikasi (HTTP ${response.statusCode}).',
        );
      }
    } catch (e) {
      return ApiKeyTestResult(
        isValid: false,
        message: 'Gagal terhubung ke Google Gemini API: $e',
      );
    }
  }

  /// Menjalankan validasi testing terlebih dahulu, JIKA valid baru disimpan dan dihubungkan
  static Future<ApiKeyTestResult> validateAndSaveCustomApiKey(
      String newApiKey) async {
    final cleanKey = newApiKey.trim();

    // 1. Uji koneksi & validitas kunci ke Google Gemini terlebih dahulu
    final testResult = await testApiKey(cleanKey);

    // 2. Jika TIDAK valid: jangan simpan, jangan hubungkan!
    if (!testResult.isValid) {
      return testResult;
    }

    // 3. Jika VALID: simpan ke SharedPreferences & perbarui cache aktif
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefCustomKeyName, cleanKey);
    _cachedActiveApiKey = cleanKey;

    return const ApiKeyTestResult(
      isValid: true,
      message: 'API Key terverifikasi valid dan berhasil dihubungkan!',
    );
  }

  /// Mereset kembali ke Kunci Default sistem
  static Future<void> resetToDefaultApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefCustomKeyName);
    _cachedActiveApiKey = null;
  }

  /// Membandingkan 2 Karung dalam 1 FOTO TUNGGAL (karung sampel dan aktual dijejerkan berdampingan)
  static Future<InspectionResult> compareSideBySidePhoto({
    required String imageBase64,
  }) async {
    const String singlePhotoPrompt = '''
Anda adalah auditor Quality Control (QC) ahli percetakan karung plastik/sak (woven bag / packaging sack).
Tugas Anda memeriksa SATU FOTO yang memuat DUA KARUNG yang dijejerkan berdampingan:
- Karung pertama adalah Karung Sample Standar (Master Proof) sebagai acuan mutu (biasanya di sebelah KIRI).
- Karung kedua adalah Karung Hasil Cetak Aktual Mesin Produksi yang sedang diperiksa (biasanya di sebelah KANAN).

Identifikasi kedua karung pada foto tersebut, lalu bandingkan secara teliti apakah cetakan aktual sudah mirip/sesuai dengan sample master atau belum.
Periksa 4 parameter kritis:
1. Akurasi Teks & Nomor: berat bersih (contoh Netto: 50kg), nomor izin/Kementan, nama merk, nomor batch, font, dan typo.
2. Kesesuaian Warna: apakah tinta pudar, meleset, salah campuran warna dibanding sample.
3. Presisi Posisi & Alignment: margin kiri-kanan, logo miring (skew), pergeseran gambar, atau terpotong jahitan karung.
4. Cacat Fisik Printing: noda/cipratan tinta (ink smudge/splatter), bagian botak/cetakan bolong (voids), garis tinta bocor.

Catatan penting:
- Abaikan lekukan atau lipatan fisik bahan karung dan bayangan pencahayaan ruangan, fokuslah murni pada grafis dan cetakan tinta.
- Nilai similarity_score dari 0 sampai 100:
  - Skor >= 85: status "PASS" (Mirip & Memenuhi Standar)
  - Skor 70 - 84: status "REVIEW" (Ada sedikit deviasi minor yang perlu dicek ulang)
  - Skor < 70: status "REJECT" (Tidak Mirip / Cacat Fatal)
- Berikan "score_justification" yang menguraikan secara logis alasan di balik perolehan persentase similarity_score (misalnya: parameter apa saja yang sempurna/mirip 100%, serta bagian mana yang menyebabkan pengurangan/penalti skor).

Kembalikan HANYA dokumen JSON dengan struktur persis seperti ini:
{
  "similarity_score": 90,
  "status": "PASS",
  "is_match": true,
  "summary": "Ringkasan evaluasi komparasi cetak dalam 1-2 kalimat.",
  "score_justification": "Penjelasan detail alasan mengapa persentase skor ini diberikan (poin yang sesuai vs penyebab pengurangan poin).",
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

    return _sendInspectionRequest(
      systemPrompt: singlePhotoPrompt,
      imageBase64List: [imageBase64],
    );
  }

  /// Membandingkan 2 Foto Terpisah (Foto Sample & Foto Aktual)
  static Future<InspectionResult> compareSackPrinting({
    required String sampleBase64,
    required String actualBase64,
  }) async {
    const String twoPhotosPrompt = '''
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
- Nilai similarity_score dari 0 sampai 100:
  - Skor >= 85: status "PASS" (Mirip & Memenuhi Standar)
  - Skor 70 - 84: status "REVIEW" (Ada sedikit deviasi minor yang perlu dicek ulang)
  - Skor < 70: status "REJECT" (Tidak Mirip / Cacat Fatal)
- Berikan "score_justification" yang menguraikan secara logis alasan di balik perolehan persentase similarity_score (misalnya: parameter apa saja yang sempurna/mirip 100%, serta bagian mana yang menyebabkan pengurangan/penalti skor).

Kembalikan HANYA dokumen JSON dengan struktur persis seperti ini:
{
  "similarity_score": 90,
  "status": "PASS",
  "is_match": true,
  "summary": "Ringkasan evaluasi komparasi cetak dalam 1-2 kalimat.",
  "score_justification": "Penjelasan detail alasan mengapa persentase skor ini diberikan (poin yang sesuai vs penyebab pengurangan poin).",
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

    return _sendInspectionRequest(
      systemPrompt: twoPhotosPrompt,
      imageBase64List: [sampleBase64, actualBase64],
    );
  }

  /// Fungsi bersama untuk mengirimkan request analisis visual ke Google Gemini API
  static Future<InspectionResult> _sendInspectionRequest({
    required String systemPrompt,
    required List<String> imageBase64List,
  }) async {
    final apiKey = await getActiveApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception(
        'Kunci API Google Gemini belum tersedia. Buka menu Pengaturan (ikon gear) untuk menambahkan API Key, atau isi GEMINI_API_KEY pada file .env.',
      );
    }

    final activeModel = await getActiveModel();
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$activeModel:generateContent?key=${apiKey.trim()}',
    );

    final List<Map<String, dynamic>> parts = [
      {'text': systemPrompt},
    ];

    for (final b64 in imageBase64List) {
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': b64,
        }
      });
    }

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': parts,
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
      String errorMessage = 'Galat status HTTP ${response.statusCode}';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson['error']?['message'] != null) {
          errorMessage = errJson['error']['message'].toString();
        }
      } catch (_) {
        errorMessage = response.body;
      }

      if (response.statusCode == 404) {
        throw Exception(
          'Model "$activeModel" tidak tersedia (HTTP 404). Silakan pilih Gemini 3.1 Flash Lite di menu Pengaturan. Detail: $errorMessage',
        );
      } else if (response.statusCode == 400) {
        throw Exception(
          'Permintaan ditolak AI (400 Bad Request): $errorMessage',
        );
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        throw Exception(
          'API Key tidak memiliki izin akses (HTTP ${response.statusCode}). Detail: $errorMessage',
        );
      } else if (response.statusCode == 429) {
        throw Exception(
          'Batas kuota panggilan Gemini API tercapai (Rate Limit 429). Tunggu beberapa detik lalu coba lagi.',
        );
      } else {
        throw Exception(
          'Galat Gemini API (${response.statusCode}): $errorMessage',
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
      final partsList = content?['parts'] as List<dynamic>?;
      if (partsList == null || partsList.isEmpty) {
        throw Exception('Konten analisis AI tidak ditemukan.');
      }

      String rawText = partsList[0]['text']?.toString() ?? '';

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
      return InspectionResult.fromJson(parsedData, modelUsed: activeModel);
    } catch (e) {
      throw Exception('Gagal membaca data hasil analisis AI: $e');
    }
  }
}
