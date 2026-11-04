import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/inspection_result.dart';

class InspectionResultCard extends StatelessWidget {
  final InspectionResult result;
  final VoidCallback onReset;

  const InspectionResultCard({
    super.key,
    required this.result,
    required this.onReset,
  });

  Color _getStatusPrimaryColor() {
    switch (result.status.toUpperCase()) {
      case 'PASS':
        return const Color(0xFF16A34A); // Green 600
      case 'REVIEW':
        return const Color(0xFFD97706); // Amber 600
      case 'REJECT':
      default:
        return const Color(0xFFDC2626); // Red 600
    }
  }

  Color _getStatusBgColor() {
    switch (result.status.toUpperCase()) {
      case 'PASS':
        return const Color(0xFFF0FDF4); // Green 50
      case 'REVIEW':
        return const Color(0xFFFFFBEB); // Amber 50
      case 'REJECT':
      default:
        return const Color(0xFFFEF2F2); // Red 50
    }
  }

  Color _getStatusBorderColor() {
    switch (result.status.toUpperCase()) {
      case 'PASS':
        return const Color(0xFFBBF7D0); // Green 200
      case 'REVIEW':
        return const Color(0xFFFDE68A); // Amber 200
      case 'REJECT':
      default:
        return const Color(0xFFFECACA); // Red 200
    }
  }

  IconData _getStatusIcon() {
    switch (result.status.toUpperCase()) {
      case 'PASS':
        return Icons.verified;
      case 'REVIEW':
        return Icons.warning_amber_rounded;
      case 'REJECT':
      default:
        return Icons.gpp_bad;
    }
  }

  String _getStatusHeading() {
    switch (result.status.toUpperCase()) {
      case 'PASS':
        return 'LULUS STANDAR (PASS)';
      case 'REVIEW':
        return 'PERIKSA ULANG (REVIEW)';
      case 'REJECT':
      default:
        return 'TIDAK SESUAI (REJECT)';
    }
  }

  String _getStatusSubtitle() {
    switch (result.status.toUpperCase()) {
      case 'PASS':
        return 'Cetakan memenuhi standar toleransi sample proof.';
      case 'REVIEW':
        return 'Ada deviasi minor, disarankan verifikasi ulang supervisor QC.';
      case 'REJECT':
      default:
        return 'Ditemukan deviasi signifikan dibanding sample master.';
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = now.day.toString().padLeft(2, '0');
    final month = months[now.month - 1];
    final year = now.year;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour:$minute WIB';
  }

  void _copyReportToClipboard(BuildContext context) {
    final reportText = '''
📋 LAPORAN INSPEKSI QC CETAK KARUNG (AIScann)
Tanggal : ${_formatTimestamp()}
Hasil   : ${_getStatusHeading()}
Skor    : ${result.similarityScore}%
Model   : ${result.modelUsed}

Ringkasan:
${result.summary}

Alasan Perolehan Skor (${result.similarityScore}%):
${result.scoreJustification}

Detail Parameter:
• Akurasi Teks & Nomor: ${result.textAccuracy.match ? 'SESUAI' : 'MENYIMPANG'} - ${result.textAccuracy.notes}
• Kesesuaian Warna    : ${result.colorFidelity.match ? 'SESUAI' : 'MENYIMPANG'} - ${result.colorFidelity.notes}
• Presisi Posisi      : ${result.alignment.match ? 'SESUAI' : 'MENYIMPANG'} - ${result.alignment.notes}
• Cacat Fisik Printing: ${result.defects.isEmpty ? 'Nihil cacat terdeteksi' : result.defects.join('; ')}

Instruksi Operator Mesin:
${result.recommendations}
'''.trim();

    Clipboard.setData(ClipboardData(text: reportText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Ringkasan laporan QC berhasil disalin ke clipboard!'),
        backgroundColor: Color(0xFF0F766E),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusPrimaryColor();
    final statusBg = _getStatusBgColor();
    final statusBorder = _getStatusBorderColor();

    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Garis aksen warna status di bagian paling atas
          Container(height: 6, color: statusColor),

          // 1. Hero Verdict Header (Sertifikat Hasil QC)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: statusBg,
              border: Border(
                bottom: BorderSide(color: statusBorder),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Meteran Skor Kemiripan Melingkar (Circular Score Gauge)
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (result.similarityScore / 100).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${result.similarityScore}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'SKOR',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: statusColor.withValues(alpha: 0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Info Status & Timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Status Tegas
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(), size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(
                              _getStatusHeading(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getStatusSubtitle(),
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 11, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
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

          // 2. Konten Hasil Analisis & Parameter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ringkasan Cepat AI
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC), // Slate 50
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFF0F766E),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kesimpulan QC Otomatis:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              result.summary,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Penjelasan Alasan Perolehan Skor Persentase
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.analytics_outlined,
                              color: statusColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Analisis Alasan Skor (${result.similarityScore}%):',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.scoreJustification,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Bagian Evaluasi 4 Parameter Kritis
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Evaluasi Parameter Cetak:',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '4 Parameter Kritis',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 1. Akurasi Teks, Merk & Nomor
                _buildParameterCard(
                  icon: Icons.text_fields_rounded,
                  title: 'Akurasi Teks & Nomor',
                  subtitle: 'Typo, Netto/Kg, No. Kementan, Font, Batch',
                  isMatch: result.textAccuracy.match,
                  notes: result.textAccuracy.notes,
                ),
                const SizedBox(height: 8),

                // 2. Kesesuaian Warna & Tinta
                _buildParameterCard(
                  icon: Icons.palette_outlined,
                  title: 'Kesesuaian Warna & Tinta',
                  subtitle: 'Deviasi pigmen warna, kepekatan, tinta pudar',
                  isMatch: result.colorFidelity.match,
                  notes: result.colorFidelity.notes,
                ),
                const SizedBox(height: 8),

                // 3. Presisi Posisi & Alignment
                _buildParameterCard(
                  icon: Icons.crop_free_rounded,
                  title: 'Presisi Posisi & Alignment',
                  subtitle: 'Margin tepi, kemiringan logo, jarak jahitan',
                  isMatch: result.alignment.match,
                  notes: result.alignment.notes,
                ),
                const SizedBox(height: 8),

                // 4. Temuan Cacat Fisik Printing
                _buildDefectsCard(),
                const SizedBox(height: 16),

                // 3. Instruksi / Rekomendasi Operator Mesin (Work Order Card)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Amber 50
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing_outlined,
                              color: Color(0xFFD97706),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Instruksi / Tindakan Operator Mesin:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.recommendations,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF78350F),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Model AI & Versi Info Tag
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.memory, size: 12, color: Color(0xFF0F766E)),
                        const SizedBox(width: 5),
                        Text(
                          'Dianalisis dengan ${result.modelUsed}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Tombol Aksi Utama (Reset & Salin Laporan)
                Row(
                  children: [
                    // Tombol Salin Laporan ke Clipboard / WA
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _copyReportToClipboard(context),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text(
                            'Salin Laporan',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Scan Ulang / Karung Lainnya
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: onReset,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Periksa Karung Baru',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isMatch,
    required String notes,
  }) {
    final statusColor = isMatch ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final statusBg = isMatch ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final statusBorder = isMatch ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isMatch ? const Color(0xFFE2E8F0) : statusBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris Parameter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: statusColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMatch ? Icons.check_circle : Icons.cancel,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMatch ? 'SESUAI' : 'MENYIMPANG',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Catatan Detail Analisis
          if (notes.isNotEmpty && notes != '-') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isMatch ? const Color(0xFFF8FAFC) : const Color(0xFFFFF1F2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                border: Border(
                  top: BorderSide(
                    color: isMatch ? const Color(0xFFF1F5F9) : const Color(0xFFFECACA),
                  ),
                ),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: 12,
                  color: isMatch ? const Color(0xFF334155) : const Color(0xFF991B1B),
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefectsCard() {
    final bool hasDefects = result.defects.isNotEmpty;
    final statusColor = hasDefects ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final statusBg = hasDefects ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final statusBorder = hasDefects ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasDefects ? statusBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasDefects ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    size: 18,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cacat Fisik Printing',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Noda tinta, void/botak, bleeds, garis bocor',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasDefects ? Icons.error_outline : Icons.check,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasDefects ? '${result.defects.length} CACAT' : 'NIHIL CACAT',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasDefects)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
                border: Border(top: BorderSide(color: Color(0xFFFECACA))),
              ),
              child: Column(
                children: result.defects.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final defect = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$index. ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            defect,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Permukaan cetakan bersih dan bebas dari cacat fisik.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
