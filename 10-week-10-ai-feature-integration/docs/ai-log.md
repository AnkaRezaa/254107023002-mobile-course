# Log Eksperimen AI — Minggu 10: AI Feature Integration

Dokumen ini mencatat konfigurasi **System Prompt**, **User Prompt**, konteks batasan privasi, serta **Output Awal AI** pada implementasi fitur *Chat Interface dengan AI* di aplikasi `campus_notify`.

---

## Praktikum 1: Chat Interface dengan AI

### 1. Struktur Prompt Design untuk Mobile

Sesuai dengan prinsip *Prompt Design untuk Mobile* (System Prompt, User Prompt, Konteks, dan Batasan), prompt dirancang sebagai berikut:

#### A. System Prompt (Persona & Guardrails)
```text
Kamu adalah Asisten Kampus cerdas dan ramah untuk aplikasi Campus Notify.
Tugasmu adalah membantu mahasiswa menjawab pertanyaan seputar informasi akademik, jadwal perkuliahan, beasiswa, dan fasilitas kampus.
Aturan:
1. Jawab dalam Bahasa Indonesia yang sopan, jelas, dan ringkas (maksimal 2–3 kalimat).
2. Fokus pada konteks perkuliahan dan kebutuhan mahasiswa.
3. Jangan pernah meminta, menerima, atau membocorkan data pribadi sensitif (seperti NIK, kata sandi, nomor rekening, atau nomor telepon).
```

#### B. User Prompt (Input Pengguna)
```text
Halo asisten, bagaimana alur pengisian KRS untuk semester genap dan kapan batas akhirnya?
```

#### C. Konteks yang Dilampirkan (Context)
* **Aplikasi**: `campus_notify` (Mobile Assistant Mahasiswa).
* **Pengguna**: Mahasiswa aktif kampus.
* **Model AI**: Google Gemini (`models/gemini-3.8-flash`).
* **Media Transmisi**: HTTPS REST API (`generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent`).
* **Penyimpanan Kunci**: `FlutterSecureStorage` (terenkripsi, tidak di-hardcode).

#### D. Batasan Keamanan & Filter Privasi (Client-Side Guardrails)
Sebelum pesan diteruskan ke cloud AI API, aplikasi menjalankan validasi regex pada layer `ChatNotifier`:
```dart
final nikRegex = RegExp(r'\b\d{16}\b');
final phoneRegex = RegExp(r'\b(08\d{8,11}|(\+62)\d{9,12})\b');
```
Jika terdeteksi NIK atau nomor kontak, permintaan langsung dicegat di sisi klien dengan pesan:
> *"⚠️ Peringatan Keamanan: Pertanyaan Anda terdeteksi memuat data sensitif (NIK atau Nomor Telepon). Demi privasi, data pribadi tidak diizinkan untuk dikirim ke AI API."*

---

### 2. Output Awal AI (Raw Output)

Berikut adalah respons aktual yang dihasilkan oleh Google Gemini API (`gemini-3.8-flash`):

```text
Halo! Alur pengisian KRS semester genap dilakukan secara mandiri melalui Portal Akademik Kampus setelah menyelesaikan her-registrasi. 
Batas akhir pengisian dan persetujuan Dosen Pembimbing Akademik adalah tanggal 10 Februari pukul 23.59 WIB. 
Pastikan Anda memilih mata kuliah sesuai kuota SKS yang telah ditentukan!
```

---

### 3. Verifikasi dan Evaluasi Output

| Kriteria Evaluasi | Status | Catatan Verifikasi |
|---|---|---|
| **Relevansi Konten** | ✅ Sesuai | Menjawab langsung pertanyaan alur dan batas waktu KRS. |
| **Kepatuhan Panjang Respons** | ✅ Sesuai | Terdiri dari 3 kalimat ringkas, nyaman dibaca pada layar perangkat mobile (*glanceable*). |
| **Gaya Bahasa & Persona** | ✅ Sesuai | Menggunakan Bahasa Indonesia formal, sopan, dan ramah sesuai persona asisten kampus. |
| **Keamanan Privasi** | ✅ Terverifikasi | Tidak ada data sensitif yang dikirim atau terekspos; kunci API tersimpan terenkripsi di Keystore/Keychain. |
| **Penanganan Error (Fallback)** | ✅ Terverifikasi | Jika API Key kosong atau terjadi kegagalan jaringan, aplikasi menampilkan pesan error yang ramah pengguna, bukan crash. |

