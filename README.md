# AIScann — AI Sack Printing Inspection

Aplikasi mobile Android berbasis Flutter untuk membandingkan foto cetakan karung sample (master standar) dengan hasil cetak produksi aktual secara instan menggunakan **Google Gemini Multimodal Vision API**.

Aplikasi ini beroperasi secara **serverless & stateless** (langsung memanggil API AI dari perangkat HP tanpa backend server dan tanpa database).

---

## Fitur Utama

- **Dua Mode Pengambilan Foto Fleksibel**:
  - 📷 **Mode 1 Foto (Dijejerkan - Rekomendasi Cepat)**: Karung master proof (kiri) dan karung hasil mesin (kanan) dijejerkan berdampingan dan difoto dalam 1 frame bersamaan. Praktis dan menghemat waktu operator!
  - 📑 **Mode 2 Foto (Terpisah)**: Memotret atau memilih foto karung master dan hasil cetak aktual secara terpisah.
- **Mekanisme Dual API Key**:
  - **Kunci Default (Sistem / `.env`)**: Siap digunakan langsung tanpa perlu memasukkan kunci secara manual.
  - **Kunci Kustom Pengguna**: Tambahkan API key sendiri di menu Pengaturan dengan **Validasi Otomatis (Pre-Testing)** sebelum disimpan.
- **Model Gemini Generasi Baru**:
  - Rekomendasi utama: `gemini-3.1-flash-lite` dan `gemini-3.5-flash-lite` (sangat cepat, responsif, stabil, dengan kuota harian hingga 500 RPD / 15 RPM).
  - Pilihan model lainnya: `gemini-3.8-flash`, `gemini-3-flash-preview`, `gemini-3.1-pro-preview`.
- **Kompresi Otomatis di HP**: Gambar di-*downscale* ke resolusi optimal ($\le 1280\text{px}$) secara lokal sebelum dikirim untuk menghemat kuota dan mempercepat analisis.
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
│   │   ├── gemini_service.dart            # Komunikasi Gemini Vision (1 foto & 2 foto), model selector
│   │   └── image_service.dart             # Pemilih kamera & kompresor gambar lokal
│   ├── screens/
│   │   ├── scan_screen.dart               # Layar utama (pilihan mode 1/2 foto & dashboard inspeksi)
│   │   └── settings_screen.dart           # Layar pengelolaan, pemilihan model & pengujian API Key
│   └── widgets/
│       └── inspection_result_card.dart    # Kartu laporan sertifikat QC, analisis skor & tombol salin
├── assets/
│   └── icon/                              # Master launcher icon (1024x1024)
├── android/                               # Konfigurasi platform Android (Gradle Kotlin DSL)
├── test/
│   └── inspection_result_test.dart        # Unit test & self-check parsing hasil AI
├── prd.md                                 # Dokumen spesifikasi kebutuhan sistem
├── pubspec.yaml                           # Dependensi Flutter & registrasi aset
└── README.md
```

---

## Cara Menjalankan Aplikasi

Pastikan perangkat Android terhubung via USB (dengan USB Debugging aktif):
```bash
flutter pub get
flutter run
```
