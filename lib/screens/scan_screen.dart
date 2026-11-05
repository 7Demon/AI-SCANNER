import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inspection_result.dart';
import '../services/gemini_service.dart';
import '../services/image_service.dart';
import '../widgets/inspection_result_card.dart';
import 'settings_screen.dart';

enum ScanMode { single, separate }

enum ImageSlot { single, sample, actual }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode _scanMode = ScanMode.single;
  ProcessedImage? _singleImage;
  ProcessedImage? _sampleImage;
  ProcessedImage? _actualImage;
  bool _isLoading = false;
  String _loadingMessage = '';
  InspectionResult? _result;
  String? _errorMessage;
  String _activeModelDisplay = 'Gemini 3.1 Flash Lite';

  @override
  void initState() {
    super.initState();
    _loadActiveModelInfo();
  }

  Future<void> _loadActiveModelInfo() async {
    try {
      final modelId = await GeminiService.getActiveModel();
      final modelInfo = GeminiService.supportedModels.firstWhere(
        (m) => m['id'] == modelId,
        orElse: () => {'name': modelId},
      );
      if (mounted) {
        setState(() {
          _activeModelDisplay = modelInfo['name']?.split(' (').first ?? modelId;
        });
      }
    } catch (_) {}
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    _loadActiveModelInfo();
  }

  Future<void> _pickImage(ImageSlot slot, ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    final processed = await ImageService.pickAndCompressImage(source);
    if (processed != null && mounted) {
      setState(() {
        switch (slot) {
          case ImageSlot.single:
            _singleImage = processed;
            break;
          case ImageSlot.sample:
            _sampleImage = processed;
            break;
          case ImageSlot.actual:
            _actualImage = processed;
            break;
        }
        _result = null;
      });
    }
  }

  void _showImageSourceDialog(ImageSlot slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  slot == ImageSlot.single
                      ? 'Pilih Sumber Foto (2 Karung Berdampingan)'
                      : (slot == ImageSlot.sample
                          ? 'Pilih Foto Karung Sample (Master)'
                          : 'Pilih Foto Karung Cetak Mesin'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF0F766E)),
                ),
                title: const Text('Ambil Foto dengan Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Jepret langsung objek karung di tempat'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(slot, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF1D4ED8)),
                ),
                title: const Text('Pilih dari Galeri Foto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan foto yang tersimpan di HP'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(slot, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzePrinting() async {
    if (_scanMode == ScanMode.single && _singleImage == null) return;
    if (_scanMode == ScanMode.separate &&
        (_sampleImage == null || _actualImage == null)) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Mengirim data ke Google Gemini Vision...';
      _errorMessage = null;
      _result = null;
    });

    try {
      final InspectionResult result;
      if (_scanMode == ScanMode.single) {
        result = await GeminiService.compareSideBySidePhoto(
          imageBase64: _singleImage!.base64Data,
        );
      } else {
        result = await GeminiService.compareSackPrinting(
          sampleBase64: _sampleImage!.base64Data,
          actualBase64: _actualImage!.base64Data,
        );
      }

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
      _singleImage = null;
      _sampleImage = null;
      _actualImage = null;
      _result = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canAnalyze = _scanMode == ScanMode.single
        ? (_singleImage != null && !_isLoading)
        : (_sampleImage != null && _actualImage != null && !_isLoading);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.document_scanner, size: 22, color: Color(0xFF2DD4BF)),
            SizedBox(width: 10),
            Text(
              'AIScann',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Pengaturan API Key & Model',
            onPressed: _openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Bar Model AI yang Aktif
            InkWell(
              onTap: _openSettings,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A), // Emerald green pulse dot
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Model AI: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _activeModelDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ganti',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 14, color: Color(0xFF0F766E)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Pilihan Mode: 1 Foto Berdampingan vs 2 Foto Terpisah
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0), // Slate 200
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      title: '1 Foto (Dijejerkan)',
                      subtitle: 'Paling Cepat & Praktis',
                      icon: Icons.photo_camera,
                      isSelected: _scanMode == ScanMode.single,
                      onTap: () {
                        if (_scanMode != ScanMode.single) {
                          setState(() {
                            _scanMode = ScanMode.single;
                            _result = null;
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildModeTab(
                      title: '2 Foto (Terpisah)',
                      subtitle: 'Master & Aktual Terpisah',
                      icon: Icons.burst_mode,
                      isSelected: _scanMode == ScanMode.separate,
                      onTap: () {
                        if (_scanMode != ScanMode.separate) {
                          setState(() {
                            _scanMode = ScanMode.separate;
                            _result = null;
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tampilan Slot Foto sesuai Mode
            if (_scanMode == ScanMode.single)
              _buildSingleImageSection()
            else
              _buildSeparateImagesSection(),

            const SizedBox(height: 20),

            // Tombol Utama Analisis AI
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: canAnalyze ? _analyzePrinting : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E), // Teal 700
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: canAnalyze ? 2 : 0,
                  shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Menganalisis Cetakan...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Bandingkan & Analisis Cetakan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Indikator Proses Loading Detail
            if (_isLoading) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCFBF1)), // Teal 100
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Color(0xFF0F766E), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Model: $_activeModelDisplay',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Memeriksa akurasi teks, warna, alignment & cacat tinta...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // Red 50
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)), // Red 200
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Pemeriksaan Gagal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFF7F1D1D),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (_errorMessage!.contains('API Key') ||
                        _errorMessage!.contains('Pengaturan') ||
                        _errorMessage!.contains('401') ||
                        _errorMessage!.contains('403') ||
                        _errorMessage!.contains('404')) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: _openSettings,
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Buka Pengaturan API Key & Model'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Hasil Analisis QC
            if (_result != null)
              InspectionResultCard(
                result: _result!,
                sampleImageBytes: _scanMode == ScanMode.single
                    ? _singleImage?.bytes
                    : _sampleImage?.bytes,
                actualImageBytes: _scanMode == ScanMode.single
                    ? null
                    : _actualImage?.bytes,
                isSingleMode: _scanMode == ScanMode.single,
                onReset: _resetAll,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleImageSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF0F766E), // Deep Teal
            child: Row(
              children: [
                const Icon(Icons.view_column, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1 Foto Berdampingan (Side-by-Side)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Kiri: Sample (Master)  |  Kanan: Aktual Mesin',
                        style: TextStyle(
                          color: Color(0xFF99F6E4), // Teal 200
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_singleImage != null)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _singleImage = null;
                        _result = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),

          // Area Viewfinder / Image Display
          if (_singleImage != null) ...[
            SizedBox(
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _singleImage!.bytes,
                    fit: BoxFit.cover,
                  ),
                  // Overlay Label Kiri / Kanan
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_left, size: 14, color: Colors.white),
                              Text(
                                'KIRI: Sample Master',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'KANAN: Cetak Mesin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.arrow_right, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dimensi & Ukuran File di Pojok Bawah
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_singleImage!.compressedWidth}×${_singleImage!.compressedHeight} • ${_singleImage!.formattedSize}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tombol Ganti Foto
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFF1F5F9), // Slate 100
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Foto siap dianalisis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showImageSourceDialog(ImageSlot.single),
                    icon: const Icon(Icons.sync, size: 14),
                    label: const Text('Ganti Foto', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Viewfinder Mockup Kosong (Panduan Operator)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Visual Guide Frame
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), // Slate 100
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Zone Kiri
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8).withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, size: 28, color: Color(0xFF1D4ED8)),
                                SizedBox(height: 6),
                                Text(
                                  'KIRI',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                                Text(
                                  'Karung Sample\n(Master Proof)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Garis Tengah Pembagi
                        Container(
                          width: 1,
                          color: const Color(0xFFCBD5E1),
                        ),
                        // Zone Kanan
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.print, size: 28, color: Color(0xFF0F766E)),
                                SizedBox(height: 6),
                                Text(
                                  'KANAN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                                Text(
                                  'Karung Aktual\n(Hasil Mesin)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jejerkan kedua karung berdampingan di lantai/meja,\nlalu jepret satu foto bersamaan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tombol Cepat: Ambil Kamera & Pilih Galeri
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSlot.single, ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text(
                              'Ambil Foto Kamera',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSlot.single, ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 16),
                            label: const Text(
                              'Galeri',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF334155),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildSeparateImagesSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildImageCard(
            title: '1. Karung Sample',
            subtitle: 'Master Standar',
            badgeColor: const Color(0xFF1D4ED8), // Blue 700
            image: _sampleImage,
            onTap: () => _showImageSourceDialog(ImageSlot.sample),
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
            badgeColor: const Color(0xFF0F766E), // Teal 700
            image: _actualImage,
            onTap: () => _showImageSourceDialog(ImageSlot.actual),
            onClear: () {
              setState(() {
                _actualImage = null;
                _result = null;
              });
            },
          ),
        ),
      ],
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),

          // Area Gambar / Placeholder
          InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 180,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${image.compressedWidth}×${image.compressedHeight} (${image.formattedSize})',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: const Color(0xFFF8FAFC),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sentuh untuk\njepret / pilih foto',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
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
