import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inspection_result.dart';
import '../services/gemini_service.dart';
import '../services/image_service.dart';
import '../widgets/inspection_result_card.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ProcessedImage? _sampleImage;
  ProcessedImage? _actualImage;
  bool _isLoading = false;
  String _loadingMessage = '';
  InspectionResult? _result;
  String? _errorMessage;

  Future<void> _pickImage(bool isSample, ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    final processed = await ImageService.pickAndCompressImage(source);
    if (processed != null && mounted) {
      setState(() {
        if (isSample) {
          _sampleImage = processed;
        } else {
          _actualImage = processed;
        }
        // Jika sebelumnya ada hasil, bersihkan karena gambar baru diunggah
        _result = null;
      });
    }
  }

  void _showImageSourceDialog(bool isSample) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.teal),
              title: const Text('Jepret dengan Kamera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(isSample, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.teal),
              title: const Text('Pilih dari Galeri HP'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(isSample, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzePrinting() async {
    if (_sampleImage == null || _actualImage == null) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Mengirim foto ke Google Gemini Vision...';
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await GeminiService.compareSackPrinting(
        sampleBase64: _sampleImage!.base64Data,
        actualBase64: _actualImage!.base64Data,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _resetAll() {
    setState(() {
      _sampleImage = null;
      _actualImage = null;
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AIScann',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'QC Inspeksi Cetak Karung',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Instruksi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: BorderSide(color: Colors.teal.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.center_focus_strong, color: Colors.teal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih atau jepret Karung Sample (Master) & Karung Hasil Cetak Aktual untuk dianalisis.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dua Kotak Pemilih Gambar (Sample vs Aktual)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildImageCard(
                    title: '1. Karung Sample',
                    subtitle: 'Master Standar',
                    badgeColor: Colors.blue.shade700,
                    image: _sampleImage,
                    onTap: () => _showImageSourceDialog(true),
                    onClear: () {
                      setState(() {
                        _sampleImage = null;
                        _result = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageCard(
                    title: '2. Cetak Aktual',
                    subtitle: 'Hasil Mesin',
                    badgeColor: Colors.teal.shade700,
                    image: _actualImage,
                    onTap: () => _showImageSourceDialog(false),
                    onClear: () {
                      setState(() {
                        _actualImage = null;
                        _result = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol Analisis Utama
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_sampleImage != null &&
                        _actualImage != null &&
                        !_isLoading)
                    ? _analyzePrinting
                    : null,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.compare_arrows),
                label: Text(
                  _isLoading ? 'Menganalisis Cetakan...' : 'Bandingkan Cetakan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Loading status message
            if (_isLoading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _loadingMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.teal.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Pesan Galat / Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: BorderSide(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Pemeriksaan Gagal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Hasil Analisis QC
            if (_result != null)
              InspectionResultCard(
                result: _result!,
                onReset: _resetAll,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required String subtitle,
    required Color badgeColor,
    required ProcessedImage? image,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: badgeColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (image != null)
                  InkWell(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),

          // Area Gambar / Placeholder
          InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 170,
              child: image != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          image.bytes,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${image.compressedWidth}x${image.compressedHeight} (${image.formattedSize})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 38,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sentuh untuk\njepret / pilih foto',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
