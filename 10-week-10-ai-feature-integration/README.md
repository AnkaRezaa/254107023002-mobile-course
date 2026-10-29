# 10-week-10-ai-feature-integration

Modul pembelajaran Minggu ke-10 ini berfokus pada **AI Feature Integration**, yaitu mengintegrasikan layanan model bahasa besar (*Large Language Models* / LLM seperti Google Gemini) ke dalam aplikasi mobile Flutter secara aman, efisien, dan berarsitektur bersih.

---

## Konsep Integrasi Fitur AI

Integrasi AI pada perangkat bergerak membutuhkan pertimbangan ketat terkait keamanan kunci API, biaya komputasi, batas kecepatan (*rate limit*), dan proteksi data pribadi pengguna.

| Komponen Arsitektur | Penjelasan Implementasi |
|---|---|
| **Secure Key Storage** | Kunci API Google Gemini disimpan secara terenkripsi pada Keychain/Keystore perangkat via `flutter_secure_storage`, tidak pernah di-hardcode di kode sumber. |
| **Streaming Response** | Respons teks dari AI dialirkan secara bertahap (*Server-Sent Events* / SSE) sehingga pengguna tidak menunggu seluruh teks selesai di-generate. |
| **Privacy Guardrails** | Mekanisme validasi lokal untuk mendeteksi dan mencegat data sensitif (seperti NIK 16 digit dan nomor kontak) sebelum permintaan dikirimkan ke cloud AI API. |
| **Clean Architecture & State** | Pemisahan tegas antara Service layer (`AiService`), State Notifier (`ChatNotifier` Riverpod), dan Presentation layer (`ChatScreen`). |

---

## Praktikum 1 — Chat Interface dengan AI

### 1. Dependensi Proyek
Dependensi ditambahkan pada `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.0
  flutter_secure_storage: ^9.0.0
  flutter_riverpod: ^3.4.3
```

### 2. Service Layer (`AiService`)
Diimplementasikan pada `lib/ai/ai_service.dart`:
- Mendukung pemanggilan reguler (`ask(question)`) dan streaming bertahap (`askStream(question)`).
- Menggunakan endpoint Google Gemini API (`models/gemini-3.8-flash`).
- Menyediakan fungsi enkripsi penyimpanan kunci API (`saveApiKey` via `flutter_secure_storage`).
- Log perancangan System Prompt, User Prompt, dan Output Awal terdokumentasi lengkap di [`docs/ai-log.md`](docs/ai-log.md).

### 3. State Management & Privacy Filter (`ChatNotifier`)
Diimplementasikan pada `lib/features/chat/providers/chat_providers.dart`:
- **Filter Privasi**: Mencegat pengiriman NIK dan Nomor Telepon menggunakan validasi regex:
  ```dart
  final nikRegex = RegExp(r'\b\d{16}\b');
  final phoneRegex = RegExp(r'\b(08\d{8,11}|(\+62)\d{9,12})\b');
  ```
- **Streaming State**: Memperbarui potongan teks (*chunk*) yang diterima ke dalam entitas pesan secara reaktif.

### 4. Antarmuka Chat (`ChatScreen`)
Diimplementasikan pada `lib/features/chat/chat_screen.dart`:
- Dialog konfigurasi API Key dinamis tanpa perlu restart aplikasi.
- Gelembung obrolan (*chat bubble*) dengan pembedaan visual antara User dan Asisten AI.
- Indikator mengetik (*typing indicator* / kursor streaming `▌`).
- Banner peringatan privasi dan status kunci API.

### 5. Pengujian (Testing)
Dua berkas pengujian otomatis dibuat:
- `test/chat_feature_test.dart`: Pengujian unit model pesan, inisialisasi notifier, dan filter privasi NIK/Nomor Telepon.
- `test/chat_screen_widget_test.dart`: Pengujian widget antarmuka, verifikasi komponen banner, dan input teks.

