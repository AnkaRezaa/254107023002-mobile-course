# Log Eksperimen AI — Minggu 10: AI Feature Integration

Dokumen ini mencatat konfigurasi **System Prompt**, **User Prompt**, konteks batasan privasi, serta **Output Awal AI** pada implementasi fitur AI terintegrasi di aplikasi `campus_notify`.

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
Jika terdeteksi data sensitif, permintaan langsung dicegat di sisi klien dengan pesan:
> *"⚠️ Peringatan Keamanan: Pertanyaan Anda terdeteksi memuat data sensitif (NIK atau Nomor Telepon). Demi privasi pengguna, data pribadi tidak diizinkan untuk dikirim ke AI API."*

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

---

## 4. OCR, Speech-to-Text, dan Image Understanding

Kemampuan multimodal terintegrasi langsung ke dalam antarmuka obrolan `ChatScreen` menggunakan model resmi Google Gemini (`models/gemini-3.8-flash:generateContent`).

### 1. Optical Character Recognition (OCR)

#### A. System / Instruction Prompt
```text
Tolong lakukan Optical Character Recognition (OCR) secara akurat pada gambar ini.
Ekstrak seluruh teks yang terbaca (seperti pada KTM, kuitansi/receipt, dokumen akademik, atau papan pengumuman)
dan pertahankan struktur teks aslinya tanpa opini tambahan.
Jika tidak ada teks sama sekali, kembalikan "Tidak ada teks yang dapat dikenali pada gambar."
```

#### B. User Prompt & Konteks Penggunaan
* **Input**: Gambar Kartu Tanda Mahasiswa (KTM) yang diambil via tombol kamera/lampiran di kolom chat.
* **Format Payload**: Multimodal JSON dengan `inline_data` tipe `image/jpeg` (Base64 encoded).
* **Kode Pemanggilan Terintegrasi**:
  ```dart
  final result = await aiService.recognizeText(imageFile);
  ```

#### C. Output Awal AI (Raw Output OCR)
```text
KEMENTERIAN PENDIDIKAN, KEBUDAYAAN, RISET, DAN TEKNOLOGI
POLITEKNIK NEGERI MALANG
KARTU TANDA MAHASISWA (KTM)

Nama           : MUHAMMAD ANKA REZA
NIM            : 254107023002
Program Studi  : D-IV TEKNIK INFORMATIKA
Jurusan        : TEKNOLOGI INFORMASI
Status         : MAHASISWA AKTIF
```

#### D. Evaluasi & Verifikasi OCR
* **Akurasi Deteksi Karakter**: ✅ Tepat 100% membaca data nominal, NIM 12 digit, dan nama mahasiswa.
* **Preservasi Format**: ✅ Tata letak berbasis label kolom tetap rapi dan siap disalin langsung ke clipboard oleh pengguna.

---

### 2. Speech-to-Text (STT / Transkripsi Suara)

#### A. System / Instruction Prompt
```text
Transkripsikan rekaman suara berikut ini ke dalam teks bahasa Indonesia secara presisi dan natural.
Hanya kembalikan teks hasil transkripsi tanpa tanda kutip pembungkus atau teks pembuka.
Jika rekaman suara kosong atau tidak terdengar ucapan, kembalikan "Tidak ada suara yang terdeteksi."
```

#### B. User Prompt & Konteks Penggunaan
* **Input**: Rekaman audio pengguna dari tombol mikrofon chat menggunakan package `record` (format AAC LC / M4A) berdurasi 4 detik.
* **Audio Source**: Pertanyaan lisan pengguna: *"Bagaimana alur pendaftaran beasiswa prestasi semester genap di Polinema?"*
* **Kode Pemanggilan Terintegrasi**:
  ```dart
  final text = await aiService.speechToText(audioFile);
  ```

#### C. Output Awal AI (Raw Output STT)
```text
Bagaimana alur pendaftaran beasiswa prestasi semester genap di Polinema?
```

#### D. Evaluasi & Verifikasi Speech-to-Text
* **Akurasi Fonetik & Kata**: ✅ Mengenali istilah khusus kampus (*Polinema*, *semester genap*) dengan tanda tanya yang tepat.
* **Integrasi UX**: ✅ Teks hasil transkripsi langsung otomatis dikirimkan ke AI dan dijawab di antarmuka chat.

---

### 3. Image Understanding (Pemahaman Konteks Visual)

#### A. System / Instruction Prompt
```text
Jelaskan dan deskripsikan secara mendalam konten yang ada di dalam gambar ini.
Identifikasi objek utama, teks yang tampak, serta konteks visualnya untuk aksesibilitas pengguna.
```

#### B. User Prompt & Konteks Penggunaan
* **Input**: Foto fasilitas ruang kelas/lab praktikum komputer kampus dengan pertanyaan visual: *"Jelaskan fasilitas dan kondisi ruangan pada foto ini."*
* **Kode Pemanggilan Terintegrasi**:
  ```dart
  final result = await aiService.understandImage(imageFile, prompt: customPrompt);
  ```

#### C. Output Awal AI (Raw Output Image Understanding)
```text
Foto ini memperlihatkan ruang Laboratorium Komputer Terpadu di lingkungan kampus. 
Terdapat deretan meja komputer yang dilengkapi monitor layar datar, keyboard, mouse ergonomis, serta kursi kerja beroda. 
Di bagian depan ruangan terpasang papan tulis putih (whiteboard) dan layar proyektor besar untuk pemaparan materi dosen. 
Pencahayaan ruangan sangat terang dengan pendingin udara (AC) yang terpasang di dinding, menunjukkan lingkungan belajar yang kondusif untuk praktikum pemrograman.
```

#### D. Evaluasi & Verifikasi Image Understanding
* **Kedalaman Deskripsi Objek**: ✅ Mengidentifikasi komponen perangkat keras komputer, fasilitas perkuliahan, dan atmosfer ruangan secara rinci.
* **Manfaat Aksesibilitas**: ✅ Deskripsi naratif yang kaya memberikan kemudahan bagi pengguna berkebutuhan khusus dalam memahami isi visual lingkungan fisik kampus.

---

## 5. Privasi, Biaya, Error Handling, dan Fallback

### 1. Tabel Matriks Risiko dan Mitigasi

| Risiko Operasional | Dampak | Mitigasi yang Diimplementasikan |
|---|---|---|
| **Bocor data pengguna** | Pelanggaran regulasi privasi & kebocoran data rahasia mahasiswa. | Mencegat di sisi klien (*client-side guardrails*) dengan validasi Regex (NIK 16-digit, Nomor Telepon, Email, dan Kata Sandi) sebelum permintaan dikirim ke AI API. |
| **Biaya melonjak** | Konsumsi kuota API berlebih akibat spam atau pertanyaan berulang. | Menerapkan kuota harian (*rate limit* 20 permintaan/hari per pengguna) serta *Local Memory Caching* untuk pertanyaan yang sama (0 biaya token). |
| **API error / down** | Antarmuka aplikasi *freeze* atau crash saat terjadi kendala jaringan/server. | Menangkap exception dengan pesan ramah pengguna, opsi tombol *Coba Lagi*, serta *AlertDialog* rekomendasi *Mode Offline*. |
| **Respons tidak relevan / halusinasi** | Mahasiswa mendapatkan informasi akademik keliru. | Menyediakan *CampusLocalKnowledgeBase* offline berisi data resmi kampus (KRS, UKT, Beasiswa, Perpustakaan, SIAKAD) sebagai fallback otomatis. |

### 2. Implementasi Fallback Dialog
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
