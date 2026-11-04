import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscureText = true;
  bool _isValidating = false;
  bool _isResetting = false;
  bool _isTestingActive = false;

  bool _isUsingCustomKey = false;
  String? _activeKeyMasked;
  String _selectedModel = GeminiService.defaultModel;
  String? _statusBannerMessage;
  bool? _statusBannerSuccess;

  // State khusus hasil pengujian Kunci Aktif (Default / Kustom)
  String? _activeKeyTestMessage;
  bool? _activeKeyTestSuccess;

  @override
  void initState() {
    super.initState();
    _refreshKeyStatus();
  }

  Future<void> _refreshKeyStatus() async {
    final isCustom = await GeminiService.isUsingCustomKey();
    final activeKey = await GeminiService.getActiveApiKey();
    final model = await GeminiService.getActiveModel();

    String? masked;
    if (activeKey != null && activeKey.isNotEmpty) {
      if (activeKey.length > 8) {
        masked =
            '${activeKey.substring(0, 6)}...${activeKey.substring(activeKey.length - 4)}';
      } else {
        masked = '••••••••';
      }
    }

    if (mounted) {
      setState(() {
        _isUsingCustomKey = isCustom;
        _activeKeyMasked = masked;
        _selectedModel = model;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _keyController.text = data.text!.trim();
      });
    }
  }

  Future<void> _validateAndConnect() async {
    final inputKey = _keyController.text.trim();
    if (inputKey.isEmpty) {
      setState(() {
        _statusBannerSuccess = false;
        _statusBannerMessage = 'Masukkan API Key terlebih dahulu.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isValidating = true;
      _statusBannerSuccess = null;
      _statusBannerMessage = 'Menguji validitas API Key ke Google Gemini...';
    });

    final result = await GeminiService.validateAndSaveCustomApiKey(inputKey);

    if (mounted) {
      setState(() {
        _isValidating = false;
        _statusBannerSuccess = result.isValid;
        _statusBannerMessage = result.message;
        if (result.isValid) {
          _keyController.clear();
        }
      });

      await _refreshKeyStatus();

      if (result.isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ API Key terverifikasi valid dan berhasil dihubungkan!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _isResetting = true);
    await GeminiService.resetToDefaultApiKey();
    await _refreshKeyStatus();

    if (mounted) {
      setState(() {
        _isResetting = false;
        _activeKeyTestMessage = null;
        _activeKeyTestSuccess = null;
        _statusBannerSuccess = true;
        _statusBannerMessage = 'Kembali menggunakan Kunci Default sistem.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telah dikembalikan ke Kunci Default bawaan.'),
          backgroundColor: Color(0xFF475569),
        ),
      );
    }
  }

  Future<void> _testActiveKey() async {
    final activeKey = await GeminiService.getActiveApiKey();
    if (activeKey == null || activeKey.isEmpty) {
      setState(() {
        _activeKeyTestSuccess = false;
        _activeKeyTestMessage = 'Tidak ada API Key yang aktif saat ini.';
      });
      return;
    }

    setState(() {
      _isTestingActive = true;
      _activeKeyTestSuccess = null;
      _activeKeyTestMessage = 'Menguji koneksi ke Google Gemini API...';
    });

    final testResult = await GeminiService.testApiKey(activeKey);

    if (mounted) {
      setState(() {
        _isTestingActive = false;
        _activeKeyTestSuccess = testResult.isValid;
        _activeKeyTestMessage = testResult.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                testResult.isValid ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  testResult.isValid
                      ? (_isUsingCustomKey
                          ? '✓ Kunci Kustom Valid & Berhasil Terhubung!'
                          : '✓ Kunci Default Valid & Berhasil Terhubung!')
                      : '✕ Gagal Terhubung: ${testResult.message}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: testResult.isValid
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        title: const Text(
          'Pengaturan & Konfigurasi AI',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Kartu Status Kunci Aktif
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isUsingCustomKey
                      ? const Color(0xFF99F6E4) // Teal 200
                      : const Color(0xFFE2E8F0), // Slate 200
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isUsingCustomKey
                              ? const Color(0xFF0F766E).withValues(alpha: 0.1)
                              : const Color(0xFF475569).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isUsingCustomKey ? Icons.vpn_key : Icons.lock_outline,
                          color: _isUsingCustomKey
                              ? const Color(0xFF0F766E)
                              : const Color(0xFF475569),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isUsingCustomKey
                                  ? 'Kunci Kustom Pengguna'
                                  : 'Kunci Bawaan Sistem (Default)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              _isUsingCustomKey
                                  ? 'API Key pribadi: ${_activeKeyMasked ?? ""}'
                                  : 'Siap pakai otomatis dari server/aplikasi',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isUsingCustomKey
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isUsingCustomKey
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          _isUsingCustomKey ? 'PRIBADI' : 'DEFAULT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isUsingCustomKey
                                ? const Color(0xFF15803D)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: _isTestingActive ? null : _testActiveKey,
                            icon: _isTestingActive
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.network_check, size: 16),
                            label: const Text(
                              'Tes Koneksi API',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              side: const BorderSide(color: Color(0xFF0F766E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_isUsingCustomKey) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 38,
                          child: TextButton.icon(
                            onPressed: _isResetting ? null : _resetToDefault,
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text(
                              'Reset ke Default',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Kotak Hasil Pengujian Kunci Aktif (In-Place Feedback)
                  if (_activeKeyTestMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _activeKeyTestSuccess == true
                            ? const Color(0xFFF0FDF4)
                            : (_activeKeyTestSuccess == false
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _activeKeyTestSuccess == true
                              ? const Color(0xFFBBF7D0)
                              : (_activeKeyTestSuccess == false
                                  ? const Color(0xFFFECACA)
                                  : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _activeKeyTestSuccess == true
                                ? Icons.check_circle
                                : (_activeKeyTestSuccess == false
                                    ? Icons.error_outline
                                    : Icons.hourglass_top),
                            color: _activeKeyTestSuccess == true
                                ? const Color(0xFF16A34A)
                                : (_activeKeyTestSuccess == false
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF0F766E)),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activeKeyTestSuccess == true
                                      ? (_isUsingCustomKey
                                          ? 'HASIL: KUNCI KUSTOM VALID & TERHUBUNG'
                                          : 'HASIL: KUNCI DEFAULT VALID & AKTIF')
                                      : (_activeKeyTestSuccess == false
                                          ? 'HASIL: KONEKSI GAGAL / ERROR'
                                          : 'SEDANG MENGUJI KONEKSI...'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _activeKeyTestSuccess == true
                                        ? const Color(0xFF15803D)
                                        : (_activeKeyTestSuccess == false
                                            ? const Color(0xFF991B1B)
                                            : const Color(0xFF0F766E)),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _activeKeyTestMessage!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _activeKeyTestSuccess == true
                                        ? const Color(0xFF166534)
                                        : (_activeKeyTestSuccess == false
                                            ? const Color(0xFF7F1D1D)
                                            : const Color(0xFF334155)),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Kartu Pemilihan Model AI Gemini
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Color(0xFF0F766E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Pilihan Versi Model AI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilih model Google Gemini yang digunakan untuk inspeksi penglihatan komputer (vision).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  // Dropdown Pilihan Model
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: GeminiService.supportedModels
                                .any((m) => m['id'] == _selectedModel)
                            ? _selectedModel
                            : GeminiService.supportedModels.first['id'],
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F766E)),
                        items: GeminiService.supportedModels.map((m) {
                          final isRecommended = m['id'] == GeminiService.defaultModel;
                          return DropdownMenuItem<String>(
                            value: m['id'],
                            child: Row(
                              children: [
                                if (isRecommended)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6.0),
                                    child: Icon(Icons.star, size: 16, color: Color(0xFFD97706)),
                                  ),
                                Expanded(
                                  child: Text(
                                    m['name']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isRecommended ? FontWeight.bold : FontWeight.w500,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newModel) async {
                          if (newModel != null && newModel != _selectedModel) {
                            await GeminiService.setActiveModel(newModel);
                            setState(() {
                              _selectedModel = newModel;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Model AI berhasil diubah ke: $newModel'),
                                  backgroundColor: const Color(0xFF0F766E),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Keterangan spesifik model terpilih
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            GeminiService.supportedModels.firstWhere(
                              (m) => m['id'] == _selectedModel,
                              orElse: () => GeminiService.supportedModels.first,
                            )['description']!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Kartu Input API Key Kustom
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tambah / Ganti API Key Kustom',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sebelum disimpan, sistem otomatis menguji validitas kunci ke Google. Hanya kunci valid yang akan dihubungkan.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  // TextField Kunci
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      hintText: 'Tempelkan API Key (AIzaSy...)',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                      ),
                      prefixIcon: const Icon(Icons.key, color: Color(0xFF64748B), size: 18),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.paste, size: 18, color: Color(0xFF0F766E)),
                            tooltip: 'Tempel dari Clipboard',
                            onPressed: _pasteFromClipboard,
                          ),
                          IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setState(() => _obscureText = !_obscureText);
                            },
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Tombol Uji & Hubungkan Kunci
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isValidating ? null : _validateAndConnect,
                      icon: _isValidating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _isValidating ? 'Menguji Validitas Kunci...' : 'Uji & Hubungkan Kunci',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                ],
              ),
            ),

            // Banner Notifikasi Status
            if (_statusBannerMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _statusBannerSuccess == true
                      ? const Color(0xFFF0FDF4)
                      : (_statusBannerSuccess == false
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusBannerSuccess == true
                        ? const Color(0xFFBBF7D0)
                        : (_statusBannerSuccess == false
                            ? const Color(0xFFFECACA)
                            : const Color(0xFFFDE68A)),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _statusBannerSuccess == true
                          ? Icons.check_circle
                          : (_statusBannerSuccess == false
                              ? Icons.error_outline
                              : Icons.hourglass_top),
                      color: _statusBannerSuccess == true
                          ? const Color(0xFF16A34A)
                          : (_statusBannerSuccess == false
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706)),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusBannerMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _statusBannerSuccess == true
                              ? const Color(0xFF15803D)
                              : (_statusBannerSuccess == false
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF92400E)),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 4. Tips Pengambilan Foto untuk Operator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // Slate 100
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFF0F766E)),
                      SizedBox(width: 6),
                      Text(
                        'Tips Foto QC Optimal:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Pastikan pencahayaan cukup dan hindari pantulan lampu tajam.\n'
                    '2. Karung dibentangkan lurus tanpa lipatan berlebih.\n'
                    '3. Pada mode 1 foto: letakkan karung master di sisi kiri dan karung mesin di sisi kanan.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF475569),
                      height: 1.45,
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
}
