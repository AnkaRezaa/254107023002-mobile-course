# 12-week-12-testing-quality-assurance

Modul pembelajaran Minggu ke-12 ini berfokus pada **Testing & Quality Assurance** pada aplikasi mobile Flutter. Modul ini membahas strategi pengujian piramida (*Testing Pyramid*), penulisan *Unit Test* untuk logika dan kasus tepi (*edge cases*) dengan pola *Arrange, Act, Assert* (AAA), pengujian asinkron dan isolasi dependensi menggunakan *Fake Repository*, pengujian tampilan dan interaksi *Widget Test*, pengujian alur menyeluruh (*Integration Test*), serta evaluasi jaminan kualitas perangkat lunak menggunakan *Code Coverage*.

* **Nama Mahasiswa**: Muhammad Anka Reza
* **NIM**: 254107023002
* **Program Studi**: D-IV Teknik Informatika
* **Jurusan**: Teknologi Informasi — Politeknik Negeri Malang

---

## 1. Selamat Datang & Tujuan Pembelajaran

Fitur yang berjalan lancar di satu perangkat belum tentu bebas dari masalah atau regresi saat basis kode berkembang. Codelab ini melatih penulisan pengujian terstruktur untuk memverifikasi perilaku aplikasi, mencegah regresi, dan menjaga kualitas kode secara berkelanjutan.

### Tujuan Pembelajaran:
1. **Menentukan Jenis Pengujian**: Mengidentifikasi bagian aplikasi yang perlu diuji dengan pengujian unit, widget, atau integrasi.
2. **Pengujian Unit & Kasus Tepi**: Menulis pengujian logika bisnis dan validasi masukan mencakup kasus normal, kasus batas, dan kasus kegagalan.
3. **Pengujian Widget**: Menguji antarmuka visual, rendering status reaktif, serta simulasi interaksi pengguna (teks, tap tombol).
4. **Isolasi Dependensi**: Memisahkan sumber data dengan kontrak abstraksi (*abstract interface class*) dan memanfaatkan *Fake Repository* agar pengujian deterministik dan bebas dari fluktuasi jaringan/API nyata.
5. **Pengujian Integrasi & Cakupan Kode**: Menjalankan alur *end-to-end* pada perangkat/emulator serta mengevaluasi cakupan pengujian (*code coverage*) secara kritis.

---

## 2. Strategi Pengujian Aplikasi Flutter

### A. Piramida Pengujian (Testing Pyramid)

```text
       /\
      /  \        Integration Tests (Alur End-to-End pada Perangkat / Emulator)
     /----\       - Menjalankan alur utuh lintas modul
    /      \      - Eksekusi lebih lambat, cakupan paling komprehensif
   / Widget \     Widget Tests (UI Rendering & Interaksi Pengguna)
  /  Tests   \    - Render visual tanpa emulator fisik, cepat
 /------------\   - Memverifikasi tampilan, state, dan event tap/input
/  Unit Tests  \  Unit Tests (Fungsi, Validasi, Aturan Bisnis & Repository)
----------------  - Sangat cepat, terisolasi, mudah diperbaiki & otomatis
```

### B. Karakteristik & Perbandingan Jenis Pengujian

| Jenis Pengujian | Yang Diperiksa | Target Pengujian | Kecepatan & Biaya | Contoh pada `campus_notify` |
|---|---|---|---|---|
| **Unit Test** | Satu fungsi atau objek logika murni tanpa render UI | Aturan validasi, transformasi data, state notifier, service | Sangat Cepat, Biaya Rendah | Validasi judul tugas/pengumuman (`isValidTaskTitle`), parsing entitas |
| **Widget Test** | Tampilan visual dan interaksi satu/beberapa widget | Layout widget, pesan error form, interaksi tap/scroll, empty state | Cepat, Berjalan di Test Environment (tanpa HP) | Form `TaskPage` menampilkan error saat tombol simpan ditekan dengan input kosong |
| **Integration Test** | Alur lengkap aplikasi dari awal hingga akhir (*End-to-End*) | Integrasi UI, navigasi, state, dan repository pada device/emulator | Lambat, Butuh Device/Emulator Aktif | Pengguna membuka aplikasi $\rightarrow$ navigasi ke halaman tugas $\rightarrow$ mengetik judul $\rightarrow$ simpan $\rightarrow$ memverifikasi item muncul di daftar |

### C. Merancang Kode yang Mudah Diuji (Testable Architecture)

Logika bisnis yang bercampur langsung di dalam widget pohon render (*build method*) atau terikat erat ke panggilan HTTP nyata sangat sulit diuji secara terisolasi. Oleh karena itu, prinsip arsitektur yang diterapkan adalah:
1. **Pemisahan Tanggung Jawab (*Separation of Concerns*)**:
   * **Widget**: Hanya menangani presentasi visual dan menangkap interaksi pengguna.
   * **Service / Use Case**: Menangani logika orkestrasi dan validasi bisnis.
   * **Repository**: Menangani komunikasi sumber data (*local storage* atau *remote API*).
2. **Pembalikan Ketergantungan (*Dependency Inversion*)**:
   * Menggunakan kontrak antarmuka (`abstract interface class TaskRepository`).
   * Service dan Widget tidak bergantung pada implementasi konkret, melainkan pada kontrak abstraksi.
   * Pada tahap pengujian, repositori nyata dapat diganti dengan **`FakeTaskRepository`** terkendali yang dapat disimulasikan untuk menghasilkan data sukses maupun memicu pelemparan `Exception`.
