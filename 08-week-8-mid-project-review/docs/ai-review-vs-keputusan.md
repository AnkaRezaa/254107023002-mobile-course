# Evaluasi AI Code Review vs Keputusan Final Mahasiswa

Dokumen ini mencatat interaksi review kode berbasis kecerdasan buatan (*AI Code Review*) untuk Pull Request fitur validasi pengumuman (`feat/announcements-validation`). Seluruh saran AI diverifikasi secara kritis berlandaskan prinsip Clean Architecture, kebenaran fungsional, dan cakupan pengujian unit.

---

## 1. Prompt AI Challenge

Prompt yang dikirimkan kepada AI Senior Flutter Developer:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## 2. Output Mentah dari AI Reviewer (5 Temuan)

### Temuan 1: Validasi Boundary Edge-Case pada String Judul
* **Level**: Blocker
* **Alasan**: `AddAnnouncement` menggunakan `title.trim().isEmpty`. Namun pada `add_announcement_test.dart`, hanya diuji input string spasi `'   '`. Belum ada test case untuk string kosong murni `''`, karakter escape whitespace (`'\n'`, `'\t'`), atau pembatasan panjang karakter maksimum (*max length*).
* **Usulan Kode AI**:
  ```dart
  test('mengembalikan LocalFailure saat judul adalah string kosong murni', () async {
    final result = await useCase(title: '');
    expect(result.failure, isA<LocalFailure>());
  });
  ```

### Temuan 2: Pengujian Jalur Kegagalan Repository (Failure Path Test)
* **Level**: Saran
* **Alasan**: `FakeAnnouncementRepository` pada unit test hanya mengembalikan respons sukses (`failure: null`). Belum ada pengujian simulasi ketika repository mengembalikan `ServerFailure` atau kegagalan penyimpanan data. Use case harus dipastikan meneruskan kegagalan tersebut tanpa merusak format record.
* **Usulan Kode AI**:
  ```dart
  test('meneruskan failure dari repository saat penambahan data gagal', () async {
    repository.shouldFail = true;
    final result = await useCase(title: 'Judul Valid');
    expect(result.failure, isA<ServerFailure>());
    expect(result.announcement, isNull);
  });
  ```

### Temuan 3: Menampilkan Feedback Error Langsung Menggunakan BuildContext di Use Case
* **Level**: Blocker
* **Alasan**: AI menyarankan agar pesan error validasi langsung memicu dialog/snackbar dengan mengoper parameter `BuildContext context` ke dalam method `call()` di `AddAnnouncement` agar UI tidak perlu mengelola state error secara manual.
* **Usulan Kode AI**:
  ```dart
  // Saran AI (Pelanggaran Arsitektur!):
  import 'package:flutter/material.dart';

  class AddAnnouncement {
    Future<void> call({required BuildContext context, required String title}) async {
      if (title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Judul tidak boleh kosong')),
        );
      }
    }
  }
  ```

### Temuan 4: Standarisasi Tipe Kembalian (Result / Either vs Dart Records)
* **Level**: Saran
* **Alasan**: Kembalian use case menggunakan Dart record `({Announcement? announcement, Failure? failure})`. Secara teori, kedua properti dapat bernilai `null` bersamaan atau terisi bersamaan. Penggunaan sealed class seperti `Result<T>` atau `Either<Failure, T>` lebih *type-safe* dan memaksa penanganan kasus secara komprehensif.
* **Usulan Kode AI**:
  ```dart
  sealed class Result<T> {}
  class Success<T> extends Result<T> { final T data; Success(this.data); }
  class Error<T> extends Result<T> { final Failure failure; Error(this.failure); }
  ```

### Temuan 5: Pemindahan Berkas Use Case ke `core/usecases/` dan Pengubahan Nama
* **Level**: Saran
* **Alasan**: AI menyarankan agar seluruh use case dipindahkan ke folder umum `lib/core/usecases/` dan diubah namanya menjadi `CreateAnnouncementUseCase` agar seragam dengan pola repositori monolitik.
* **Usulan Kode AI**:
  Pindahkan file dari `features/announcements/domain/usecases/add_announcement.dart` ke `core/usecases/create_announcement_use_case.dart`.

---

## 3. Verifikasi & Matriks Keputusan Mahasiswa

| No | Temuan AI | Level | Rekomendasi AI | Keputusan | Alasan & Argumen Teknis Mahasiswa |
|---|---|:---:|---|:---:|---|
| 1 | Boundary Edge-Case Test | Blocker | Tambah pengujian input `''` dan newline | **DITERIMA** | **Terbukti benar**. Cakupan unit test harus menguji boundary condition ekstrem (`''`, `\n`) untuk mencegah regresi logika. |
| 2 | Repository Failure Path Test | Saran | Tambah simulasi error repository di fake | **DITERIMA** | **Terbukti benar**. Menguji jalur kegagalan (*error path*) merupakan standar wajib agar use case terbukti mampu meneruskan kegagalan data source. |
| 3 | Injeksi BuildContext ke Use Case | Blocker | Oper `BuildContext` & panggil `ScaffoldMessenger` | **DITOLAK KERAS** | **Melanggar Dependency Rule Clean Architecture!** Domain layer adalah *pure Dart* dan dilarang keras mengimpor framework Flutter (`flutter/material.dart`). Urusan presentasi UI dan Snackbar adalah tanggung jawab Widget/Presentation layer. |
| 4 | Result/Either vs Dart Records | Saran | Migrasi ke sealed class Result | **DITERIMA (Fase Lanjut)** | **Saran konstruktif**. Untuk saat ini record pattern dipertahankan demi konsistensi dengan use case `GetAnnouncements`, dan direncanakan untuk refactoring sealed class pada paruh kedua. |
| 5 | Pindah use case ke `core/` | Saran | Pindah file ke `lib/core/usecases/` | **DITOLAK** | **Melanggar struktur Feature-First!** Pada modularitas *feature-first*, use case spesifik pengumuman harus tetap berada dalam `features/announcements/domain/usecases/`, bukan dicampur ke dalam `core/`. |

---

## 4. Kesimpulan Pembelajaran AI Review

1. **AI Bukan Penentu Kebenaran Mutlak**: AI rentan menyarankan kemudahan instan (seperti mengoper `BuildContext` ke dalam Domain Use Case pada Temuan 3) yang merusak arsitektur demi mengurangi baris kode di UI.
2. **Kritis terhadap Dependency Rule**: Mahasiswa harus selalu mempertahankan aturan sterilitas domain: **Domain tidak boleh mengenal UI, Database, maupun Network**.
3. **Pemanfaatan AI yang Sehat**: Saran AI sangat bernilai untuk menemukan *blindspot* pengujian batas (*edge cases*) dan pengujian jalur kegagalan (*failure path*).
