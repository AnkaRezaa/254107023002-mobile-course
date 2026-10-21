# Mid-Project Review Checklist & Git Hygiene Audit

Dokumen ini berisi catatan audit riwayat Git, perbaikan pesan commit lama ke standar Conventional Commits, serta lembar evaluasi kesiapan proyek tengah semester (*Mid-Project Review*).

---

## 1. Audit Git Hygiene & Simulasi Perbaikan Commit

### A. Temuan Masalah pada Riwayat Git Sebelumnya
1. **Commit Langsung ke `main`**: Tidak adanya alur integrasi bertahap melalui branch `develop` atau branch fitur terpisah.
2. **Pesan Commit Non-Standar**: Penggunaan judul bab/modul praktikum tanpa tipe dan scope yang jelas (`week 7 : Tugas...`, `fix week 7 no sqflite`).
3. **Ketiadaan Branch Integrasi**: Belum terdapat branch `develop` di repository remote maupun lokal.

### B. Tabel Perbaikan Pesan Commit (Sebelum vs Sesudah)

| Hash Commit Lama | Pesan Commit Lama | Usulan Pesan Konvensional (Conventional Commit) | Alasan Perbaikan & Bukti Teknis |
|---|---|---|---|
| `f6c0202` | `fix week 7 no sqflite` | `fix(announcements): replace sqflite dependency with in-memory mock repository` | Format lama ambigu dan tidak menyebutkan scope. Format baru memperjelas komponen yang diperbaiki (`announcements`) serta solusi teknis yang diterapkan. |
| `ad8a7d6` | `week 7 : Presentation, DI, dan verifikasi` | `feat(presentation): implement clean architecture ui and riverpod di wiring` | Format lama hanya menyalin judul modul. Format baru menggunakan tipe `feat(presentation)` dengan penjelasan teknis penambahan UI dan DI wiring. |
| `b23ea1d` | `week 7 : Domain dan data per fitur` | `feat(domain,data): define pure entities, repository contracts and dto models` | Format lama tidak mendeskripsikan artefak teknis. Format baru memperjelas komponen domain (entity, contract) dan data (model DTO) yang dibuat. |

---

## 2. Checklist Kesiapan Proyek Tengah Semester (Mid-Project Readiness)

| Aspek Penilaian | Indikator Kesiapan | Status | Catatan Verifikasi |
|---|---|:---:|---|
| **Arsitektur & Sterilitas** | Struktur *feature-first* Clean Architecture diterapkan konsisten | Sesuai | Terbagi jelas ke dalam `domain/`, `data/`, dan `presentation/` di `lib/features/`. |
| **Dependency Rule** | Domain layer 100% steril dari framework UI, SQLite, Dio, dan Firebase | Sesuai | Lulus pengujian sterilitas regex grep tanpa temuan. |
| **Analisis Statis Mesin** | `flutter analyze` bersih tanpa error maupun warning | Sesuai | 0 issue / clean pass. |
| **Pengujian Unit Otomatis** | `flutter test` berjalan hijau (100% passed) | Sesuai | Pengujian domain use case menggunakan FakeRepository berhasil. |
| **Kebersihan Kode** | `dart format` terformat rapi sesuai standar Dart | Sesuai | Seluruh file di-format dengan `dart format .`. |
| **Disiplin Git Flow** | Menggunakan branch `develop` dan `feature/*`, PR kecil terfokus (< 300 baris) | Sesuai | Branch `develop` aktif, PR #2 (< 300 baris) sukses di-review & di-merge, Issue #1 tertutup otomatis, dan branch fitur dihapus. |
| **Dokumentasi & Portofolio** | README lengkap memuat status, screenshot, dan cara menjalankan | Sesuai | Panduan instalasi dan dokumentasi visual tersedia lengkap. |
