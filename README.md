# AIScann — AI Sack Printing Inspection

[![Download APK](https://img.shields.io/badge/Download-APK%20(Release)-0F766E?style=for-the-badge&logo=android&logoColor=white)](https://github.com/7Demon/AI-SCANNER/releases)
[![GitHub Release](https://img.shields.io/github/v/release/7Demon/AI-SCANNER?style=for-the-badge&color=2DD4BF)](https://github.com/7Demon/AI-SCANNER/releases)

Aplikasi mobile Android berbasis Flutter untuk membandingkan foto cetakan karung sample (master standar) dengan hasil cetak produksi aktual secara instan menggunakan **Google Gemini Multimodal Vision API**.

Aplikasi ini beroperasi secara **serverless & stateless** (langsung memanggil API AI dari perangkat HP tanpa backend server dan tanpa database).

---

## 📥 Unduh Aplikasi (Download APK)

Aplikasi AIScann dapat langsung dipasang di smartphone Android tanpa perlu setup developer:

| Varian APK | Arsitektur CPU | Ukuran | Rekomendasi Penggunaan | Tautan Unduh Langsung |
|---|---|---|---|---|
| ⚡ **ARM64 (Super Ringan)** | `arm64-v8a` | **~15–18 MB** | **Rekomendasi Utama** untuk 95%+ HP Android modern| [⬇️ Download APK (ARM64)](https://github.com/7Demon/AI-SCANNER/releases/latest/download/app-arm64-v8a-release.apk) |
| 📱 **ARM32** | `armeabi-v7a` | **~15–18 MB** | Untuk perangkat Android tipe lama (32-bit) | [⬇️ Download APK (ARM32)](https://github.com/7Demon/AI-SCANNER/releases/latest/download/app-armeabi-v7a-release.apk) |
| 📦 **Universal** | `All-in-one` | **~40–50 MB** | Kompatibel dengan semua jenis arsitektur HP Android | [⬇️ Download APK (Universal)](https://github.com/7Demon/AI-SCANNER/releases/latest/download/app-release.apk) |

> 💡 Kunjungi halaman **[GitHub Releases](https://github.com/7Demon/AI-SCANNER/releases)** untuk melihat catatan rilis lengkap, changelog, dan mengunduh seluruh aset rilis.

---

## Fitur Utama

- **Dua Mode Pengambilan Foto Fleksibel**:
  - 📷 **Mode 1 Foto (Dijejerkan - Rekomendasi Cepat)**: Karung master proof (kiri) dan karung hasil mesin (kanan) dijejerkan berdampingan dan difoto dalam 1 frame bersamaan. Praktis dan menghemat waktu operator!
  - 📑 **Mode 2 Foto (Terpisah)**: Memotret atau memilih foto karung master dan hasil cetak aktual secara terpisah.
- **📄 Download Laporan Resmi (PDF)**:
  - Ekspor dokumen inspeksi QC resmi format A4 multi-halaman langsung ke folder Download perangkat HP.
  - Memuat identitas dokumen, timestamp, model AI, status PASS/REVIEW/REJECT, meteran skor, kesimpulan AI, tabel 4 parameter deviasi, instruksi teknis operator mesin, dan **bukti visual foto komparasi fisik**.
- **⚡ Super Ringan & Bebas Lag (Performa Tinggi)**:
  - Kompresi foto didelegasikan langsung ke C++ Skia hardware native Android (`<250 ms`).
  - Alokasi Base64 secara *lazy on-demand* (hemat 50% RAM heap).
  - Perakitan PDF dan pembacaan gambar berjalan di background worker isolate (`compute`), menjamin UI tetap mulus stabil pada 60 FPS.
  - Pengecilan ukuran APK via *R8 Code & Resource Shrinking*.
- **Mekanisme Dual API Key**:
  - **Kunci Default (Sistem / `.env`)**: Siap digunakan langsung tanpa perlu memasukkan kunci secara manual.
  - **Kunci Kustom Pengguna**: Tambahkan API key sendiri di menu Pengaturan dengan **Validasi Otomatis (Pre-Testing)** sebelum disimpan.
- **Model Gemini Generasi Baru**:
  - Rekomendasi utama: `gemini-3.1-flash-lite` dan `gemini-3.5-flash-lite` (sangat cepat, responsif, stabil, dengan kuota harian hingga 500 RPD / 15 RPM).
  - Pilihan model lainnya: `gemini-3.8-flash`, `gemini-3-flash-preview`, `gemini-3.1-pro-preview`.
- **Keputusan QC Instan**:
  - 🟢 **LULUS STANDAR (PASS)** jika skor $\ge 85\%$
  - 🟡 **PERIKSA ULANG (REVIEW)** jika skor $70 - 84\%$
  - 🔴 **TIDAK SESUAI (REJECT)** jika skor $< 70\%$
- **Meteran Skor Melingkar & Analisis Alasan Skor**:
  - Visual *Circular Score Gauge* dengan persentase skor kemiripan.
  - Kartu khusus **Analisis Alasan Skor**: AI menjelaskan secara transparan mengapa nilai skor tersebut diberikan (poin yang identik vs parameter yang memotong nilai/penalti).
- **Rincian Evaluasi 4 Aspek Kritis**:
  1. Akurasi Teks, Merk & Nomor (Typo, Netto/Berat, No. Kementan, Font, Batch).
  2. Kesesuaian Warna & Tinta (Pudar, meleset, salah campuran pigmen).
  3. Presisi Posisi & Alignment (Margin, miring/skew, batas jahitan).
  4. Temuan Cacat Fisik Printing (Noda/cipratan tinta, bagian botak/voids, garis bocor).
- **Instruksi Tindakan Operator Mesin**: Rekomendasi teknis korektif langsung untuk operator mesin cetak.
- **Fitur 1-Tap "Salin Laporan"**: Sekali klik untuk menyalin seluruh ringkasan laporan inspeksi QC ke clipboard untuk langsung dibagikan ke WhatsApp grup QC/pabrik.
- **Logo Resmi AIScann**: Ikon peluncur Android kustom bernuansa *Industrial QC Scanner*.

---

## Struktur Proyek

```text
d:\PROJECTS\AIScann/
├── .env                                   # Konfigurasi kunci default Google Gemini API
├── lib/
│   ├── main.dart                          # Tema Industrial Teal Slate & titik masuk aplikasi
│   ├── models/
│   │   └── inspection_result.dart         # Model data hasil analisis, alasan skor, & parsing JSON
│   ├── services/
│   │   ├── gemini_service.dart            # Komunikasi Gemini Vision, retry loop, model selector
│   │   ├── image_service.dart             # Pemilih kamera & kompresor gambar native C++ Skia
│   │   └── report_service.dart            # Generator dokumen PDF laporan QC resmi di worker isolate
│   ├── screens/
│   │   ├── scan_screen.dart               # Layar utama (pilihan mode 1/2 foto & dashboard inspeksi)
│   │   └── settings_screen.dart           # Layar pengelolaan, pemilihan model & pengujian API Key
│   └── widgets/
│       └── inspection_result_card.dart    # Kartu laporan QC, analisis skor, download PDF & tombol salin
├── assets/
│   └── icon/                              # Master launcher icon (1024x1024)
├── android/                               # Konfigurasi platform Android (Gradle Kotlin DSL & R8 rules)
├── test/
│   └── inspection_result_test.dart        # Unit test & self-check parsing hasil AI
├── prd.md                                 # Dokumen spesifikasi kebutuhan sistem
├── pubspec.yaml                           # Dependensi Flutter & registrasi aset
└── README.md
```

---

## Cara Menjalankan & Mengompilasi Aplikasi

### Menjalankan Langsung di HP (Debug Mode):
```bash
flutter run
```

### Mengompilasi ke APK Release (Super Ringan):
```bash
flutter build apk --split-per-abi
```
File APK yang dihasilkan siap pakai:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
