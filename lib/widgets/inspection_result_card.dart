import 'package:flutter/material.dart';
import '../models/inspection_result.dart';

class InspectionResultCard extends StatelessWidget {
  final InspectionResult result;
  final VoidCallback onReset;

  const InspectionResultCard({
    super.key,
    required this.result,
    required this.onReset,
  });

  Color _getStatusColor() {
    switch (result.status) {
      case 'PASS':
        return const Color(0xFF2E7D32); // Green
      case 'REVIEW':
        return const Color(0xFFE65100); // Deep Orange / Amber
      case 'REJECT':
      default:
        return const Color(0xFFC62828); // Red
    }
  }

  IconData _getStatusIcon() {
    switch (result.status) {
      case 'PASS':
        return Icons.check_circle_outline;
      case 'REVIEW':
        return Icons.warning_amber_rounded;
      case 'REJECT':
      default:
        return Icons.highlight_off;
    }
  }

  String _getStatusTitle() {
    switch (result.status) {
      case 'PASS':
        return 'LULUS / MIRIP (PASS)';
      case 'REVIEW':
        return 'PERIKSA ULANG (REVIEW)';
      case 'REJECT':
      default:
        return 'TIDAK MIRIP (REJECT)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Status Utama
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            color: statusColor,
            child: Row(
              children: [
                Icon(_getStatusIcon(), color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.isMatch
                            ? 'Cetakan memenuhi standar toleransi'
                            : 'Cetakan menyimpang dari sample',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${result.similarityScore}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ringkasan AI
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.teal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.summary,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Rincian Pemeriksaan Cetak:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // 1. Akurasi Teks
                _buildInspectionItem(
                  icon: Icons.text_fields,
                  title: 'Akurasi Teks & Nomor (Typo / Netto / Merk)',
                  isMatch: result.textAccuracy.match,
                  notes: result.textAccuracy.notes,
                ),

                // 2. Kesesuaian Warna
                _buildInspectionItem(
                  icon: Icons.palette_outlined,
                  title: 'Kesesuaian Warna & Tinta',
                  isMatch: result.colorFidelity.match,
                  notes: result.colorFidelity.notes,
                ),

                // 3. Presisi Posisi & Simetri
                _buildInspectionItem(
                  icon: Icons.crop_free,
                  title: 'Presisi Posisi & Alignment',
                  isMatch: result.alignment.match,
                  notes: result.alignment.notes,
                ),

                // 4. Cacat Fisik Printing
                const SizedBox(height: 8),
                const Text(
                  'Cacat Fisik Printing:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                if (result.defects.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tidak ada cacat tinta / cetakan terdeteksi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: result.defects.map((defect) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                defect,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                // Rekomendasi Operator
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: BorderSide(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade900,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Rekomendasi Tindakan Operator:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.recommendations,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown.shade900,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Scan Baru / Reset
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Scan Karung Lainnya (Reset)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  Widget _buildInspectionItem({
    required IconData icon,
    required String title,
    required bool isMatch,
    required String notes,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMatch ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: BorderSide(
            color: isMatch ? Colors.green.shade200 : Colors.red.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isMatch ? Icons.check_circle : Icons.cancel,
              color: isMatch ? Colors.green.shade700 : Colors.red.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isMatch
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notes,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMatch
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

