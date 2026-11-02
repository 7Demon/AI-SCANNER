# AIScann — AI Sack Printing Inspection

Aplikasi mobile Android berbasis Flutter untuk membandingkan foto cetakan karung sample (master standar) dengan hasil cetak produksi aktual secara instan menggunakan **Google Gemini Multimodal Vision API**.

Aplikasi ini beroperasi secara **serverless & stateless** (langsung memanggil API AI dari perangkat HP tanpa backend server dan tanpa database).

---

## Konfigurasi API Key via `.env`

API Key Google Gemini ditaruh di dalam berkas `.env` di root proyek:

```env
# .env
GEMINI_API_KEY=AIzaSy...
```

Aplikasi membaca kunci ini secara otomatis saat dijalankan, sehingga pengguna/operator **tidak perlu memasukkan API key secara manual di aplikasi HP**.

---

## Fitur Utama

- **Foto Sample vs Aktual**: Memotret atau memilih 2 foto karung langsung dari kamera atau galeri HP.
- **Kompresi Otomatis di HP**: Gambar di-*downscale* ke resolusi optimal ($\le 1280\text{px}$) secara lokal sebelum dikirim untuk menghemat kuota dan mempercepat analisis.
- **Direct-to-Gemini Vision**: Menggunakan model `gemini-1.5-flash` dengan format keluaran terstruktur (*JSON Schema Mode*).
- **Keputusan QC Instan**:
  - **LULUS / MIRIP (PASS)** (Hijau) jika skor $\ge 85\%$
  - **PERIKSA ULANG (REVIEW)** (Kuning) jika skor $70 - 84\%$
  - **TIDAK MIRIP (REJECT)** (Merah) jika skor $< 70\%$
- **Rincian Evaluasi 4 Aspek**:
  1. Akurasi Teks & Typo (Netto/Berat, Nama Merk, Nomor Registrasi).
  2. Kesesuaian Warna & Tinta (Pudar, meleset, salah campuran).
  3. Presisi Posisi & Alignment (Margin, miring/skew, simetri).
  4. Cacat Fisik Printing (Noda/cipratan tinta, bagian botak/voids, garis bocor).
- **Rekomendasi Operator**: Saran teknis perbaikan mesin cetak dari AI.
- **Reset Sekali Klik**: Tombol *Scan Baru* untuk langsung mereset layar dan bersiap memeriksa karung berikutnya tanpa menyimpan tumpukan file sampah.

---

## Struktur Proyek

```text
d:\PROJECTS\AIScann/
├── .env                                   # Konfigurasi kunci Google Gemini API
├── lib/
│   ├── main.dart                          # Inisialisasi tema Teal industrial & titik masuk aplikasi
│   ├── models/
│   │   └── inspection_result.dart         # Model data hasil analisis & parsing JSON terstruktur
│   ├── services/
│   │   ├── gemini_service.dart            # Komunikasi langsung ke Gemini Vision & pembaca .env
│   │   └── image_service.dart             # Pemilih kamera & kompresor gambar lokal
│   ├── screens/
│   │   └── scan_screen.dart               # Layar utama (2 kotak foto & tombol bandingkan)
│   └── widgets/
│       └── inspection_result_card.dart    # Kartu visualisasi status QC & rincian perbedaan
├── android/                               # Konfigurasi platform Android
│   ├── app/src/main/AndroidManifest.xml   # Izin Kamera & Internet
│   └── ...
├── test/
│   └── inspection_result_test.dart        # Unit test & self-check parsing hasil AI
├── prd.md                                 # Dokumen spesifikasi kebutuhan sistem
├── pubspec.yaml                           # Dependensi Flutter & registrasi aset .env
└── README.md
```

---

## Cara Menjalankan Aplikasi

### 1. Masukkan Gemini API Key ke `.env`
Buka file `.env` di root folder proyek, lalu masukkan kunci API Anda:
```env
GEMINI_API_KEY=masukkan_api_key_anda_disini
```
*(Dapatkan API Key gratis di [Google AI Studio](https://aistudio.google.com/)).*

### 2. Jalankan di HP Android / Emulator
Pastikan perangkat Android terhubung via USB (dengan USB Debugging aktif):
```bash
flutter pub get
flutter run
```

### 3. Mulai Inspeksi Karung
1. Ketuk kotak **1. Karung Sample** $\rightarrow$ jepret foto master proof atau pilih dari galeri.
2. Ketuk kotak **2. Cetak Aktual** $\rightarrow$ jepret karung yang baru keluar dari mesin cetak.
3. Ketuk tombol **"Bandingkan Cetakan"**.
4. Dalam 2–4 detik, hasil perbandingan, skor kemiripan, dan rekomendasi akan muncul di layar.
5. Ketuk **"Scan Karung Lainnya"** untuk mereset dan memindai karung selanjutnya!

---

## Build File APK Siap Pakai

Untuk menghasilkan berkas APK yang siap diinstal ke HP mana pun di pabrik:
```bash
flutter build apk --release
```
File APK akan berada di folder `build/app/outputs/flutter-apk/app-release.apk`.
