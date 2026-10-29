# 10-week-10-ai-feature-integration

Modul pembelajaran Minggu ke-10 ini berfokus pada **AI Feature Integration**, yaitu mengintegrasikan layanan model bahasa besar (*Large Language Models* / LLM seperti Google Gemini) serta kemampuan multimodal (*Vision & Voice*) ke dalam aplikasi mobile Flutter secara terpadu, aman, efisien, dan berarsitektur bersih.

* **Nama Mahasiswa**: Muhammad Anka Reza
* **NIM**: 254107023002
* **Program Studi**: D-IV Teknik Informatika
* **Jurusan**: Teknologi Informasi — Politeknik Negeri Malang

---

## 1. Konsep Integrasi Fitur AI pada Mobile

Integrasi AI pada perangkat bergerak membutuhkan pertimbangan ketat terkait keamanan kunci API, biaya komputasi, batas kecepatan (*rate limit*), dan proteksi data pribadi pengguna.

| Komponen Arsitektur | Penjelasan Implementasi |
|---|---|
| **Secure Key Storage** | Kunci API Google Gemini disimpan secara terenkripsi pada Keychain/Keystore perangkat via `flutter_secure_storage`, tidak pernah di-hardcode di kode sumber. |
| **Multimodal Capabilities** | Terintegrasi langsung untuk Text Chatting, Optical Character Recognition (OCR), dan Speech-to-Text (Voice Input) dalam satu antarmuka obrolan. |
| **Privacy Guardrails** | Mekanisme validasi lokal untuk mendeteksi dan mencegat data sensitif (NIK 16 digit, nomor telepon, email, kata sandi) sebelum permintaan dikirimkan ke cloud AI API. |
| **Cost & Quota Control** | Batasan kuota harian (20 request/hari per pengguna) serta *Local Memory Caching* untuk pertanyaan yang sama (0 biaya token). |
| **Graceful Fallback** | Fallback otomatis ke *CampusLocalKnowledgeBase* dan *AlertDialog* 'Layanan AI Sibuk' saat terjadi kendala jaringan atau server down. |

---

## 2. Struktur Modul & Fitur yang Diintegrasikan

Fitur AI diintegrasikan menyatu ke dalam proyek `campus_notify`:
- **Service Layer**: [`lib/ai/ai_service.dart`](campus_notify/lib/ai/ai_service.dart) menggunakan endpoint model resmi Google Gemini (`models/gemini-3.8-flash:generateContent`).
- **Basis Pengetahuan Lokal**: [`lib/ai/local_knowledge_base.dart`](campus_notify/lib/ai/local_knowledge_base.dart) sebagai penyedia data resmi kampus offline.
- **State Management**: [`lib/features/chat/providers/chat_providers.dart`](campus_notify/lib/features/chat/providers/chat_providers.dart) mengelola state obrolan, privasi, biaya kuota, dan fallback dialog.
- **Antarmuka Terintegrasi**: [`lib/features/chat/chat_screen.dart`](campus_notify/lib/features/chat/chat_screen.dart) menyediakan input terpadu (Kamera OCR, Mikrofon Suara, Teks, Banner Kuota, dan Dialog Fallback).
- **Entitas Pesan**: [`lib/features/chat/models/chat_message.dart`](campus_notify/lib/features/chat/models/chat_message.dart) mendukung teks serta pratinjau lampiran gambar.

---

## 3. Matriks Risiko dan Mitigasi (Privasi & Biaya)

| Risiko Operasional | Dampak | Mitigasi yang Diimplementasikan |
|---|---|---|
| **Bocor data pengguna** | Pelanggaran regulasi privasi & kebocoran data rahasia mahasiswa. | Mencegat di sisi klien (*client-side guardrails*) dengan validasi Regex (NIK 16-digit, Nomor Telepon, Email, dan Kata Sandi) sebelum permintaan dikirim ke AI API. |
| **Biaya melonjak** | Konsumsi kuota API berlebih akibat spam atau pertanyaan berulang. | Menerapkan kuota harian (*rate limit* 20 permintaan/hari per pengguna) serta *Local Memory Caching* untuk pertanyaan yang sama (0 biaya token). |
| **API error / down** | Antarmuka aplikasi *freeze* atau crash saat terjadi kendala jaringan/server. | Menangkap exception dengan pesan ramah pengguna, opsi tombol *Coba Lagi*, serta *AlertDialog* rekomendasi *Mode Offline*. |
| **Respons tidak relevan / halusinasi** | Mahasiswa mendapatkan informasi akademik keliru. | Menyediakan *CampusLocalKnowledgeBase* offline berisi data resmi kampus (KRS, UKT, Beasiswa, Perpustakaan, SIAKAD) sebagai fallback otomatis. |

### Implementasi Fallback Dialog
```dart
try {
  final response = await aiService.ask(question);
} catch (e) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Layanan AI Sibuk'),
      content: const Text('Coba lagi nanti atau gunakan mode offline.'),
      actions: [
        TextButton(
          onPressed: () => notifier.retryLastMessage(),
          child: const Text('Coba Lagi'),
        ),
        ElevatedButton(
          onPressed: () => notifier.useOfflineFallback(),
          child: const Text('Gunakan Mode Offline'),
        ),
      ],
    ),
  );
}
```

---

## 4. Bukti Mesin Hijau (Green Machine Verification)

![Bukti Mesin Hijau - flutter analyze dan flutter test](screenshot/bukti%20mesin%20hijau.jpg)

### A. Hasil `flutter analyze --no-pub`
```bash
PS C:\laragon\www\...\campus_notify> flutter analyze --no-pub
Analyzing campus_notify...
No issues found! (ran in 4.7s)
```
*(Status: 0 issues, kode bersih dan patuh terhadap seluruh pedoman linting Dart & Flutter).*

### B. Hasil `flutter test --no-pub`
```bash
PS C:\laragon\www\...\campus_notify> flutter test --no-pub
00:04 +22: All tests passed!
```
*(Status: 22 pengujian otomatis lulus 100%, mencakup model pesan, guardrail privasi, basis data lokal, rate limiter, serta interaksi widget).*

---

## 5. Refleksi Pembelajaran

### 1. Fitur AI mana yang Anda integrasikan dan mengapa?
> **Jawaban**:  
> Fitur AI yang diintegrasikan ke dalam proyek `campus_notify` adalah **Asisten Obrolan Akademik Terpadu (Smart Campus Assistant)** yang mengombinasikan *Text Query*, *Optical Character Recognition (OCR)* untuk dokumen/KTM, dan *Speech-to-Text (Voice Input)* langsung dalam satu antarmuka obrolan (`ChatScreen`).  
> Alasan pemilihannya adalah mahasiswa membutuhkan akses cepat ke informasi akademik penting (seperti alur KRS, batas pengajuan beasiswa, dan pembayaran UKT) tanpa harus menavigasi menu portal kampus yang kompleks. Dengan integrasi tombol kamera OCR, mahasiswa dapat memotret KTM atau bukti pembayaran untuk mengekstrak teks secara instan. Sedangkan tombol mikrofon (Speech-to-Text) memberikan kemudahan input saat pengguna sedang bergerak (*on-the-go*).

### 2. Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?
> **Jawaban**:  
> Perlindungan privasi dirancang dengan arsitektur berlapis di sisi klien (*Client-Side Privacy Guardrails*):
> 1. **Client-Side Regex Scrubbing / Interception**: Pada layer `ChatNotifier`, pesan pengguna divalidasi menggunakan ekspresi reguler sebelum menyentuh jaringan. Sistem mendeteksi Nomor Induk Kependudukan (NIK 16-digit `\b\d{16}\b`), nomor kontak seluler (`08xx` atau `+62xx`), pola alamat email, dan kata sandi/PIN. Jika ditemukan, pesan langsung dicegat secara lokal dan tidak dikirimkan ke cloud AI.
> 2. **Secure Key Management**: Kunci API Google Gemini disimpan terenkripsi di Keystore (Android) / Keychain (iOS) melalui `FlutterSecureStorage`, sehingga terhindar dari risiko kebocoran akibat reverse engineering atau commit ke repositori publik.
> 3. **Prinsip Minimasi Data**: Permintaan ke AI API hanya mengirimkan teks pertanyaan tanpa melampirkan identitas perangkat (*Device ID*), data lokasi, atau riwayat profil pengguna.

### 3. Fallback apa yang Anda sediakan jika layanan AI error?
> **Jawaban**:  
> Aplikasi mengimplementasikan strategi *Graceful Degradation* berlapis:
> 1. **Pangkalan Data Lokal Kampus (`CampusLocalKnowledgeBase`)**: Berisi basis pengetahuan resmi seputar topik umum perkuliahan (KRS, Beasiswa, UKT, Perpustakaan, dan Layanan SIAKAD). Ketika API gagal merespons, sistem mencocokkan kata kunci pertanyaan pengguna ke data lokal ini.
> 2. **Fallback Dialog Interaktif**: Jika AI mengalami kendala (timeout, jaringan terputus, atau kuota habis), aplikasi menampilkan `AlertDialog` bertajuk *"Layanan AI Sibuk"* yang menawarkan opsi tombol **Coba Lagi** (*Retry*) atau **Gunakan Mode Offline** (*Local Fallback*).
> 3. **Local Response Caching**: Hasil query yang pernah diminta disimpan di memory cache lokal, sehingga pertanyaan identik berikutnya dapat dijawab secara instan dengan 0 biaya token dan 0 latensi.

### 4. Satu hal yang Anda pelajari tentang UX fitur AI di mobile?
> **Jawaban**:  
> Pelajaran terpenting mengenai UX AI pada mobile adalah **pentingnya transparansi status sistem dan pengelolaan jeda waktu (*latency gap*) bagi pengguna**. Karena pemrosesan LLM membutuhkan waktu beberapa detik, pengguna memerlukan umpan balik langsung berupa indikator mengetik (*typing indicator* / kursor streaming), informasi sisa kuota yang transparan (`Sisa Kuota: 20/20`), serta tombol alih instan ke Mode Offline. Memberikan kendali penuh kepada pengguna saat jaringan seluler tidak stabil mencegah timbulnya kebingungan atau anggapan bahwa aplikasi mengalami *crash*.

---

## 6. Dokumentasi Tangkapan Layar (Screenshots)

| Praktikum 1: Setup Key & Chat | Praktikum 2 & 3: Multimodal & Offline | Bukti Mesin Hijau: Analyze & Test |
|:---:|:---:|:---:|
| ![Praktikum 1](screenshot/praktikum%201.jpg) | ![Praktikum 2](screenshot/praktikum%202.jpg) | ![Bukti Mesin Hijau](screenshot/bukti%20mesin%20hijau.jpg) |

---

## 7. Referensi Pendukung

* [Slide Week 10: Integrasi Fitur AI](https://jti-polinema.github.io/flutter-codelab/00-slides/Week_10_AI_Feature_Integration.html)
* [Google Gemini AI API Documentation](https://ai.google.dev/)
* [Package flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
* [Package http (Dart)](https://pub.dev/packages/http)
* [Package image_picker](https://pub.dev/packages/image_picker)
* [Package record](https://pub.dev/packages/record)
* [Riverpod Documentation & State Management](https://riverpod.dev/docs/introduction/getting_started)
* [Learn Dart in Y Minutes](https://learnxinyminutes.com/dart/)
* [Dart Language Tour](https://dart.dev/guides/language/language-tour)
