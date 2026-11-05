import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/inspection_result.dart';

class PdfExportParams {
  final InspectionResult result;
  final Uint8List? sampleImageBytes;
  final Uint8List? actualImageBytes;
  final bool isSingleMode;

  const PdfExportParams({
    required this.result,
    this.sampleImageBytes,
    this.actualImageBytes,
    this.isSingleMode = false,
  });
}

class ReportExportResult {
  final bool isSuccess;
  final String? filePath;
  final String? fileName;
  final String message;

  const ReportExportResult({
    required this.isSuccess,
    this.filePath,
    this.fileName,
    required this.message,
  });
}

/// Fungsi top-level yang dieksekusi di background worker isolate via compute()
Future<Uint8List> _generatePdfDocumentBytes(PdfExportParams params) async {
  final result = params.result;
  final sampleImageBytes = params.sampleImageBytes;
  final actualImageBytes = params.actualImageBytes;
  final isSingleMode = params.isSingleMode;

  final pdf = pw.Document(
    title: 'Laporan Inspeksi QC Cetak Karung - AIScann',
    author: 'AIScann Quality Control System',
  );

  final now = DateTime.now();
  final dateStr = ReportService.formatDate(now);
  final docId = 'QC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

  // Warna status
  final PdfColor statusColor;
  final PdfColor statusBg;
  final String statusLabel;

  switch (result.status.toUpperCase()) {
    case 'PASS':
      statusColor = PdfColor.fromHex('#15803D'); // Green 700
      statusBg = PdfColor.fromHex('#DCFCE7');    // Green 100
      statusLabel = 'LULUS STANDAR (PASS)';
      break;
    case 'REVIEW':
      statusColor = PdfColor.fromHex('#B45309'); // Amber 700
      statusBg = PdfColor.fromHex('#FEF3C7');    // Amber 100
      statusLabel = 'PERIKSA ULANG (REVIEW)';
      break;
    case 'REJECT':
    default:
      statusColor = PdfColor.fromHex('#B91C1C'); // Red 700
      statusBg = PdfColor.fromHex('#FEE2E2');    // Red 100
      statusLabel = 'TIDAK SESUAI (REJECT)';
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      footer: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 0.5),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dokumen resmi dihasilkan otomatis oleh AIScann Quality Control System',
                  style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#94A3B8')),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#94A3B8')),
                ),
              ],
            ),
          ],
        );
      },
      build: (pw.Context context) {
        return [
          // 1. Header Resmi Perusahaan / QC
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#0F766E'),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          'AIScann',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        'QC VISION PRO',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#0F766E'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'LAPORAN HASIL INSPEKSI MUTU CETAK KARUNG',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0F172A'),
                    ),
                  ),
                  pw.Text(
                    'Sistem Otomatis Pembanding Master Sample vs Hasil Mesin Produksi',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColor.fromHex('#64748B'),
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'No. Dokumen: $docId',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#334155'),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Waktu: $dateStr',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#64748B'),
                    ),
                  ),
                  pw.Text(
                    'Model AI: ${result.modelUsed}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#64748B'),
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColor.fromHex('#CBD5E1'), thickness: 1),
          pw.SizedBox(height: 12),

          // 2. Banner Status Hasil & Skor Kemiripan
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: statusBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: statusColor, width: 1.2),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STATUS VERIFIKASI MUTU:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      statusLabel,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: statusColor),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${result.similarityScore}%',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      pw.Text(
                        'SKOR KEMIRIPAN',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#475569'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // 2.5 Dokumentasi Foto Bukti QC (Jika Ada Foto)
          ReportService.buildPhotosSection(
            sampleImageBytes: sampleImageBytes,
            actualImageBytes: actualImageBytes,
            isSingleMode: isSingleMode,
          ),

          // 3. Kesimpulan Eksekutif AI
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KESIMPULAN INSPEKSI:',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0F766E'),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  result.summary,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColor.fromHex('#1E293B'),
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 8),

          // 4. Analisis Alasan Perolehan Skor
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ALASAN PEROLEHAN SKOR PERSENTASE (${result.similarityScore}%):',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0F172A'),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  result.scoreJustification,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromHex('#334155'),
                    lineSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // 5. Tabel Evaluasi 4 Parameter Kritis Cetak
          pw.Text(
            'RINCIAN EVALUASI 4 PARAMETER KRITIS:',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 6),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.8),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(130),
              2: const pw.FixedColumnWidth(70),
              3: const pw.FlexColumnWidth(),
            },
            children: [
              // Header Tabel
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                children: [
                  ReportService.buildTableCell('No', isHeader: true, align: pw.TextAlign.center),
                  ReportService.buildTableCell('Parameter QC', isHeader: true),
                  ReportService.buildTableCell('Hasil', isHeader: true, align: pw.TextAlign.center),
                  ReportService.buildTableCell('Catatan Temuan & Analisis Deviasi', isHeader: true),
                ],
              ),
              // Row 1: Teks
              pw.TableRow(
                children: [
                  ReportService.buildTableCell('1', align: pw.TextAlign.center),
                  ReportService.buildTableCell('Akurasi Teks & Nomor\n(Typo, Netto/Kg, No. Izin)'),
                  ReportService.buildStatusCell(result.textAccuracy.match),
                  ReportService.buildTableCell(result.textAccuracy.notes),
                ],
              ),
              // Row 2: Warna
              pw.TableRow(
                children: [
                  ReportService.buildTableCell('2', align: pw.TextAlign.center),
                  ReportService.buildTableCell('Kesesuaian Warna & Tinta\n(Pigmen, Kepekatan, Pudar)'),
                  ReportService.buildStatusCell(result.colorFidelity.match),
                  ReportService.buildTableCell(result.colorFidelity.notes),
                ],
              ),
              // Row 3: Posisi
              pw.TableRow(
                children: [
                  ReportService.buildTableCell('3', align: pw.TextAlign.center),
                  ReportService.buildTableCell('Presisi Posisi & Alignment\n(Margin, Kemiringan, Jahitan)'),
                  ReportService.buildStatusCell(result.alignment.match),
                  ReportService.buildTableCell(result.alignment.notes),
                ],
              ),
              // Row 4: Cacat Fisik
              pw.TableRow(
                children: [
                  ReportService.buildTableCell('4', align: pw.TextAlign.center),
                  ReportService.buildTableCell('Cacat Fisik Printing\n(Noda, Void/Botak, Bleed)'),
                  ReportService.buildStatusCell(result.defects.isEmpty, trueText: 'NIHIL CACAT', falseText: 'ADA CACAT'),
                  ReportService.buildTableCell(result.defects.isEmpty
                      ? 'Permukaan cetakan bersih bebas noda tinta atau cetakan bolong.'
                      : result.defects.join('\n• ')),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // 6. Rekomendasi Tindakan Operator
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFFBEB'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#FDE68A')),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INSTRUKSI / REKOMENDASI TINDAKAN OPERATOR MESIN:',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#92400E'),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  result.recommendations,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor.fromHex('#78350F'),
                    lineSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),
        ];
      },
    ),
  );

  return pdf.save();
}

class ReportService {
  /// Format tanggal ramah cetak
  static String formatDate(DateTime dt) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  /// Membuat dokumen PDF resmi hasil inspeksi QC di background worker isolate via compute()
  static Future<Uint8List> buildPdfReportBytes(
    InspectionResult result, {
    Uint8List? sampleImageBytes,
    Uint8List? actualImageBytes,
    bool isSingleMode = false,
  }) async {
    final params = PdfExportParams(
      result: result,
      sampleImageBytes: sampleImageBytes,
      actualImageBytes: actualImageBytes,
      isSingleMode: isSingleMode,
    );
    return compute(_generatePdfDocumentBytes, params);
  }

  static pw.Widget buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColor.fromHex('#0F172A') : PdfColor.fromHex('#334155'),
        ),
      ),
    );
  }

  static pw.Widget buildStatusCell(
    bool isMatch, {
    String trueText = 'SESUAI',
    String falseText = 'MENYIMPANG',
  }) {
    final color = isMatch ? PdfColor.fromHex('#15803D') : PdfColor.fromHex('#B91C1C');
    final bg = isMatch ? PdfColor.fromHex('#DCFCE7') : PdfColor.fromHex('#FEE2E2');

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          isMatch ? trueText : falseText,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  static pw.Widget buildPhotosSection({
    Uint8List? sampleImageBytes,
    Uint8List? actualImageBytes,
    bool isSingleMode = false,
  }) {
    if (sampleImageBytes == null && actualImageBytes == null) {
      return pw.SizedBox();
    }

    if (isSingleMode && sampleImageBytes != null) {
      final image = pw.MemoryImage(sampleImageBytes);
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DOKUMENTASI FOTO INSPEKSI (MASTER & CETAK AKTUAL JEJER):',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0F766E'),
                  ),
                ),
                pw.Text(
                  'Foto Tunggal Komparasi',
                  style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#64748B')),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Container(
                height: 160,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            ),
          ],
        ),
      );
    }

    final sampleImg = sampleImageBytes != null ? pw.MemoryImage(sampleImageBytes) : null;
    final actualImg = actualImageBytes != null ? pw.MemoryImage(actualImageBytes) : null;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DOKUMENTASI FOTO BUKTI KOMPARASI QC:',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F766E'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              // Foto 1: Master Standar
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        color: PdfColor.fromHex('#1E40AF'),
                        child: pw.Text(
                          '1. MASTER STANDAR',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        height: 140,
                        child: sampleImg != null
                            ? pw.Image(sampleImg, fit: pw.BoxFit.contain)
                            : pw.Center(
                                child: pw.Text(
                                  'Tidak ada foto master',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),

              // Foto 2: Cetak Aktual
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        color: PdfColor.fromHex('#0F766E'),
                        child: pw.Text(
                          '2. CETAK AKTUAL (MESIN)',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        height: 140,
                        child: actualImg != null
                            ? pw.Image(actualImg, fit: pw.BoxFit.contain)
                            : pw.Center(
                                child: pw.Text(
                                  'Tidak ada foto aktual',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mengunduh dan menyimpan laporan PDF ke penyimpanan perangkat HP
  static Future<ReportExportResult> exportAndSavePdf(
    InspectionResult result, {
    Uint8List? sampleImageBytes,
    Uint8List? actualImageBytes,
    bool isSingleMode = false,
  }) async {
    try {
      final bytes = await buildPdfReportBytes(
        result,
        sampleImageBytes: sampleImageBytes,
        actualImageBytes: actualImageBytes,
        isSingleMode: isSingleMode,
      );
      final now = DateTime.now();
      final dateTag = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'Laporan_QC_AIScann_$dateTag.pdf';

      File? savedFile;
      String locationNotice = '';

      // 1. Coba simpan ke folder publik Download Android (/storage/emulated/0/Download)
      if (Platform.isAndroid) {
        try {
          final publicDownloadDir = Directory('/storage/emulated/0/Download');
          if (await publicDownloadDir.exists()) {
            final targetPath = '${publicDownloadDir.path}/$fileName';
            final file = File(targetPath);
            await file.writeAsBytes(bytes, flush: true);
            savedFile = file;
            locationNotice = 'Folder Download ($targetPath)';
          }
        } catch (_) {
          // Fallback ke langkah berikutnya jika permission dibatasi
        }
      }

      // 2. Coba simpan via getDownloadsDirectory() path_provider
      if (savedFile == null) {
        try {
          final downloadDir = await getDownloadsDirectory();
          if (downloadDir != null) {
            final targetPath = '${downloadDir.path}/$fileName';
            final file = File(targetPath);
            await file.writeAsBytes(bytes, flush: true);
            savedFile = file;
            locationNotice = 'Folder Download (${downloadDir.path})';
          }
        } catch (_) {}
      }

      // 3. Fallback ke getExternalStorageDirectory()
      if (savedFile == null && Platform.isAndroid) {
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            final targetPath = '${extDir.path}/$fileName';
            final file = File(targetPath);
            await file.writeAsBytes(bytes, flush: true);
            savedFile = file;
            locationNotice = 'Penyimpanan Eksternal (${extDir.path})';
          }
        } catch (_) {}
      }

      // 4. Fallback ke getApplicationDocumentsDirectory()
      if (savedFile == null) {
        final docDir = await getApplicationDocumentsDirectory();
        final targetPath = '${docDir.path}/$fileName';
        final file = File(targetPath);
        await file.writeAsBytes(bytes, flush: true);
        savedFile = file;
        locationNotice = 'Dokumen Aplikasi (${docDir.path})';
      }

      return ReportExportResult(
        isSuccess: true,
        filePath: savedFile.path,
        fileName: fileName,
        message: 'Laporan berhasil diunduh dan disimpan ke:\n$locationNotice',
      );
    } catch (e) {
      return ReportExportResult(
        isSuccess: false,
        message: 'Gagal membuat atau menyimpan laporan PDF: $e',
      );
    }
  }

  /// Membuka file PDF dengan aplikasi PDF viewer bawaan HP
  static Future<void> openPdfFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
    } catch (_) {}
  }
}

