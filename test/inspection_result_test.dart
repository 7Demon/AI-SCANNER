import 'dart:convert';
import '../lib/models/inspection_result.dart';

void main() {
  print('=== Menjalankan Self-Check InspectionResult Parsing ===');

  // Test Case 1: Status PASS dengan skor 92
  const String sampleJsonPass = '''
  {
    "similarity_score": 92,
    "status": "PASS",
    "is_match": true,
    "summary": "Hasil cetak sangat mirip dengan sample standar.",
    "analysis_details": {
      "text_accuracy": {
        "match": true,
        "notes": "Teks netto 50kg dan merk tercetak jelas."
      },
      "color_fidelity": {
        "match": true,
        "notes": "Warna hijau dan merah sesuai standar."
      },
      "alignment": {
        "match": true,
        "notes": "Posisi logo presisi di tengah."
      },
      "defects_found": []
    },
    "recommendations": "Lanjutkan proses produksi cetak."
  }
  ''';

  final result1 = InspectionResult.fromJson(jsonDecode(sampleJsonPass));
  assert(result1.similarityScore == 92, 'Score harus 92');
  assert(result1.status == 'PASS', 'Status harus PASS');
  assert(result1.isMatch == true, 'isMatch harus true');
  assert(result1.textAccuracy.match == true, 'textAccuracy harus true');
  assert(result1.colorFidelity.match == true, 'colorFidelity harus true');
  assert(result1.alignment.match == true, 'alignment harus true');
  assert(result1.defects.isEmpty, 'Defects harus kosong');
  print('✓ Test 1: PASS output parsing OK');

  // Test Case 2: Status REJECT dengan skor 55 dan daftar cacat
  const String sampleJsonReject = '''
  {
    "similarity_score": 55,
    "status": "REJECT",
    "is_match": false,
    "summary": "Ditemukan deviasi warna parah dan teks typo.",
    "analysis_details": {
      "text_accuracy": {
        "match": false,
        "notes": "Netto tercetak 40kg, seharusnya 50kg."
      },
      "color_fidelity": {
        "match": false,
        "notes": "Tinta merah terlalu gelap mengarah ke cokelat."
      },
      "alignment": {
        "match": false,
        "notes": "Logo geser 3cm ke kiri dan miring."
      },
      "defects_found": [
        "Cipratan tinta di area barcode",
        "Cetakan botak di teks komposisi"
      ]
    },
    "recommendations": "Hentikan mesin. Setel ulang silinder cetak dan bersihkan plate."
  }
  ''';

  final result2 = InspectionResult.fromJson(jsonDecode(sampleJsonReject));
  assert(result2.similarityScore == 55, 'Score harus 55');
  assert(result2.status == 'REJECT', 'Status harus REJECT');
  assert(result2.isMatch == false, 'isMatch harus false');
  assert(result2.textAccuracy.match == false, 'textAccuracy harus false');
  assert(result2.defects.length == 2, 'Defects harus berisi 2 item');
  assert(result2.defects[0].contains('Cipratan tinta'), 'Cacat 1 harus cocok');
  print('✓ Test 2: REJECT output parsing OK');

  // Test Case 3: Fallback jika JSON tidak lengkap / anomali
  final result3 = InspectionResult.fromJson({
    'similarity_score': '75',
    'status': 'REVIEW',
  });
  assert(result3.similarityScore == 75, 'Score harus di-parse dari string 75');
  assert(result3.status == 'REVIEW', 'Status harus REVIEW');
  assert(result3.defects.isEmpty, 'Defects harus fallback ke empty list');
  print('✓ Test 3: Fallback incomplete JSON OK');

  print('=== SEMUA CHECK BERHASIL! ===');
}
