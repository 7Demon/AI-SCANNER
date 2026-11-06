import 'dart:convert';
import 'dart:typed_data';
import '../lib/models/inspection_result.dart';

void main() {
  print('======================================================');
  print('    AIScann Chaos Engineering & Resiliency Test Suite');
  print('======================================================\n');

  int passed = 0;
  int failed = 0;

  void runChaosTest(String name, void Function() testFn) {
    try {
      testFn();
      print('  [PASS] $name');
      passed++;
    } catch (e, st) {
      print('  [FAIL] $name: $e');
      print('         StackTrace: ${st.toString().split('\n').take(2).join(' | ')}');
      failed++;
    }
  }

  // =========================================================================
  // GROUP 1: Model Deserialization Chaos (InspectionResult.fromJson)
  // =========================================================================
  print('--- GROUP 1: Deserialization Chaos (Corrupt & Hostile JSON) ---');

  runChaosTest('Chaos 1.1: Empty Map ({})', () {
    final result = InspectionResult.fromJson({});
    assert(result.similarityScore == 0);
    assert(result.status == 'REJECT');
    assert(result.defects.isEmpty);
  });

  runChaosTest('Chaos 1.2: Extreme Out-of-Bound Scores (-999 & 99999)', () {
    final resultNegative = InspectionResult.fromJson({'similarity_score': -999});
    assert(resultNegative.similarityScore == 0, 'Score negative harus clamp ke 0');

    final resultOver = InspectionResult.fromJson({'similarity_score': 99999});
    assert(resultOver.similarityScore == 100, 'Score over harus clamp ke 100');
  });

  runChaosTest('Chaos 1.3: Non-Numeric Similarity Score ("eighty five", "85%")', () {
    final res1 = InspectionResult.fromJson({'similarity_score': 'eighty five'});
    assert(res1.similarityScore == 0);

    final res2 = InspectionResult.fromJson({'similarity_score': '85%'});
    assert(res2.similarityScore == 0 || res2.similarityScore == 85);
  });

  runChaosTest('Chaos 1.4: Hostile analysis_details (String instead of Map)', () {
    final result = InspectionResult.fromJson({
      'similarity_score': 88,
      'status': 'PASS',
      'analysis_details': 'Everything looks great and perfect!', // String, bukan Map!
    });
    assert(result.similarityScore == 88);
    assert(result.textAccuracy.notes.isNotEmpty);
  });

  runChaosTest('Chaos 1.5: Hostile analysis_details (List instead of Map)', () {
    final result = InspectionResult.fromJson({
      'similarity_score': 90,
      'status': 'PASS',
      'analysis_details': ['text_accuracy is fine', 'colors matched'], // List, bukan Map!
    });
    assert(result.similarityScore == 90);
  });

  runChaosTest('Chaos 1.6: Hostile defects_found (String instead of List)', () {
    final result = InspectionResult.fromJson({
      'similarity_score': 60,
      'status': 'REJECT',
      'analysis_details': {
        'defects_found': 'Tidak ada cacat fatal ditemukan', // String, bukan List!
      },
    });
    assert(result.status == 'REJECT');
  });

  runChaosTest('Chaos 1.7: defects_found containing hostile non-string items', () {
    final result = InspectionResult.fromJson({
      'similarity_score': 70,
      'status': 'REVIEW',
      'analysis_details': {
        'defects_found': [null, 12345, true, {'error': 'severe'}, 'Tinta bocor'],
      },
    });
    assert(result.defects.isNotEmpty);
    assert(result.defects.contains('Tinta bocor'));
  });

  runChaosTest('Chaos 1.8: Subcategory detail as String instead of Map', () {
    final result = InspectionResult.fromJson({
      'similarity_score': 95,
      'status': 'PASS',
      'analysis_details': {
        'text_accuracy': 'Teks netto 50kg terbaca sempurna', // String, bukan Map!
        'color_fidelity': true,                              // Bool, bukan Map!
        'alignment': 100,                                    // Int, bukan Map!
      },
    });
    assert(result.similarityScore == 95);
  });

  runChaosTest('Chaos 1.9: Massive 10,000 Character Text Injection & Unicode/Emoji Bomb', () {
    final massiveText = 'Karung' * 2000 + ' 🚨⚠️🔥💯 測試 тест العربية';
    final result = InspectionResult.fromJson({
      'similarity_score': 50,
      'status': 'REJECT',
      'summary': massiveText,
      'score_justification': massiveText,
      'recommendations': massiveText,
    });
    assert(result.summary.length >= 10000);
    assert(result.status == 'REJECT');
  });

  // =========================================================================
  // GROUP 2: AI Response Extraction Chaos
  // =========================================================================
  print('\n--- GROUP 2: AI Raw Response Cleanup & Extraction Chaos ---');

  // Helper replika ekstraksi json dari GeminiService
  Map<String, dynamic> extractGeminiJson(String rawText) {
    var text = rawText.trim();
    // Cari blok ```json ... ``` atau ``` ... ```
    if (text.contains('```json')) {
      final startIndex = text.indexOf('```json') + 7;
      final endIndex = text.lastIndexOf('```');
      if (endIndex > startIndex) {
        text = text.substring(startIndex, endIndex);
      }
    } else if (text.contains('```')) {
      final startIndex = text.indexOf('```') + 3;
      final endIndex = text.lastIndexOf('```');
      if (endIndex > startIndex) {
        text = text.substring(startIndex, endIndex);
      }
    } else {
      // Cari substring pertama '{' sampai '}' terakhir
      final firstBrace = text.indexOf('{');
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        text = text.substring(firstBrace, lastBrace + 1);
      }
    }
    text = text.trim();
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
      return decoded.first as Map<String, dynamic>;
    }
    throw FormatException('Output AI bukan merupakan JSON Object yang valid.');
  }

  runChaosTest('Chaos 2.1: Gemini Output dengan Preamble & Postamble Text', () {
    const raw = '''
Halo operator QC! Berikut adalah hasil analisis komparasi cetak karung:
```json
{
  "similarity_score": 91,
  "status": "PASS",
  "summary": "Cetakan sesuai standar proof."
}
```
Semoga laporan ini membantu operasional pabrik!
''';
    final data = extractGeminiJson(raw);
    assert(data['similarity_score'] == 91);
  });

  runChaosTest('Chaos 2.2: Gemini Output JSON Tanpa Markdown Fences tapi dengan Intro', () {
    const raw = '''
Tentu, berikut datanya:
{
  "similarity_score": 82,
  "status": "REVIEW",
  "summary": "Ada sedikit pergeseran logo."
}
''';
    final data = extractGeminiJson(raw);
    assert(data['similarity_score'] == 82);
  });

  runChaosTest('Chaos 2.3: Gemini Mengembalikan Array JSON alih-alih Object', () {
    const raw = '''
[
  {
    "similarity_score": 93,
    "status": "PASS",
    "summary": "Hasil cetak presisi."
  }
]
''';
    final data = extractGeminiJson(raw);
    assert(data['similarity_score'] == 93);
  });

  // =========================================================================
  // GROUP 3: Image Service & Byte Chaos
  // =========================================================================
  print('\n--- GROUP 3: Image Service & Byte Chaos ---');

  runChaosTest('Chaos 3.1: 0-byte Empty Image Byte Array', () {
    final emptyBytes = Uint8List(0);
    final b64 = base64Encode(emptyBytes);
    assert(b64 == '');
  });

  runChaosTest('Chaos 3.2: Corrupt Random Noise Byte Array', () {
    final garbageBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0xFF]);
    final b64 = base64Encode(garbageBytes);
    assert(b64.isNotEmpty);
    final decodedBack = base64Decode(b64);
    assert(decodedBack.length == garbageBytes.length);
  });

  // =========================================================================
  // SUMMARY
  // =========================================================================
  print('\n======================================================');
  print('Chaos Testing Selesai!');
  print('Total Passed: $passed');
  print('Total Failed: $failed');
  print('======================================================');

  if (failed > 0) {
    throw Exception('Chaos testing mendeteksi $failed titik kelemahan!');
  }
}

