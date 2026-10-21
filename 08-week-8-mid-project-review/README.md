# 08-week-8-mid-project-review

Pada pertemuan kali ini saya mempelajari tentang konsep Git Flow dan strategi branching (`main`, `develop`, `feature/*`, `fix/*`), penulisan commit yang berkualitas dengan standar Conventional Commits, pembuatan Pull Request (PR) yang terstruktur, pelaksanaan peer code review yang konstruktif, pengujian statis otomatis menggunakan `flutter analyze` dan `dart format`, evaluasi kesiapan proyek tengah semester (*Mid-Project Review*), serta verifikasi kritis terhadap saran review dari AI.

---

# Konsep Git Flow dan Kolaborasi

## Strategi Branching dan Standar Kolaborasi

| Branch | Peran | Aturan |
|---|---|---|
| `main` | Selalu siap rilis ke production, dilindungi | Tidak ada commit langsung; hanya menerima merge via release/PR resmi |
| `develop` | Integrasi fitur mingguan | Target default untuk semua Pull Request fitur |
| `feature/*` | Pengerjaan fitur harian | Berumur pendek (< 3 hari), dicabangkan dari dan di-merge ke `develop` |
| `fix/*` | Perbaikan bug cepat + penambahan unit test | Menyertakan langkah reproduksi bug yang merujuk ke Issue |

---

### Praktikum 1 — Hygiene branch dan commit

1. **Audit Riwayat Git**:
   Perintah audit dijalankan pada repository project:
   ```bash
   git log --oneline -15
   git branch -a
   git status
   ```

   **Output Terminal**:
   ```text
   ce8a50e (HEAD -> main) chore: remove empty deleted file
   9ff6b44 (origin/main, origin/HEAD) Merge branch 'main' of https://github.com/AnkaRezaa/254107023002-mobile-course
   86810e4 week 7 :  Tugas, refleksi, dan referensi
   f8641a9 week 7 : Refactoring, testing, dan error umum
   df040f4 week 7 :  AI Challenge
   ad8a7d6 week 7 : Presentation, DI, dan verifikasi
   f6c0202 fix week 7 no sqflite
   b23ea1d week 7 : Domain dan data per fitur
   90f8dc4 Dibuat menggunakan Colab
   f4b6fb8 chore: snapshot before clean architecture
   5b61357 week 7 :  Clean Architecture
   35a10d0 week 6 : Tugas, refleksi, dan referensi
   47eb934 week 6 : Refactoring, testing, dan error umum
   92e0f93 week 6 : ai challenge
   72d498c praktikum 3: Payload, tiga app state, klik dan topi

   * main
     remotes/origin/HEAD -> origin/main
     remotes/origin/main

   On branch main
   Your branch is ahead of 'origin/main' by 1 commit.
   Untracked files:
     ../08-week-8-mid-project-review/screenshots/
   ```

   **Dokumentasi Screenshot Audit**:
   ![Audit Git Riwayat Minggu 5](screenshots/screenshot_audit_week_5.jpg)
   ![Audit Git Riwayat Minggu 6-7](screenshots/schreenshot_audit_week_6.jpg)

   **Temuan dan Analisis Masalah**:
   - **Commit Langsung ke `main`**: Seluruh pengerjaan commit sebelumnya dilakukan langsung pada branch utama (`HEAD -> main`) tanpa melalui branch fitur (`feature/*`) atau branch staging/integrasi (`develop`). Hal ini berisiko merusak kestabilan kode produksi.
   - **Pesan Commit Non-Standar**: Pesan commit sebelumnya cenderung menggunakan judul sub-bab modul praktikum (misal `week 7 : Tugas, refleksi, dan referensi`, `week 6 : ai challenge`, `fix week 7 no sqflite`, atau `Dibuat menggunakan Colab`). Pesan tersebut tidak mengikuti konvensi industri (*Conventional Commits*) sehingga sulit dilacak perubahannya oleh sistem CI/CD maupun anggota tim.
   - **Ketiadaan Branch `develop`**: Output `git branch -a` membuktikan bahwa repository belum memiliki branch `develop` sebagai target default integrasi mingguan.
   - **Untracked Directory**: Ditemukan folder `08-week-8-mid-project-review/screenshots/` yang belum dilacak oleh Git dan perlu ditambahkan ke repository.

2. **Branching yang Benar & Commit Konvensional**:
   Sesuai prinsip Git Flow, branch integrasi `develop` dibuat dari `main` dan di-push ke remote repository sebagai target integrasi Pull Request. Selanjutnya, branch kerja baru `feat/announcements-validation` dibuat dari `develop` untuk mengisolasi pengerjaan fitur validasi:
   ```bash
   git checkout -b develop
   git push -u origin develop
   git checkout -b feat/announcements-validation
   ```

   **Dokumentasi Screenshot Branching**:
   ![Pembuatan Branch develop dan feat/announcements-validation di Terminal](screenshots/new_branches.jpg)
   ![Daftar Branch di GitHub Web](screenshots/githubweb_branches.jpg)

   **Pengerjaan Fitur & Commit Konvensional**:
   Satu perubahan logis dibuat dengan menambahkan use case `AddAnnouncement` dan unit test `add_announcement_test.dart`, lalu di-commit menggunakan standar Conventional Commits:
   ```bash
   git add lib/features/announcements/domain/usecases/add_announcement.dart test/add_announcement_test.dart
   git commit -m "feat(announcements): validasi judul kosong + test"
   git push -u origin feat/announcements-validation
   ```

   **Dokumentasi Screenshot Commit di GitHub**:
   ![Riwayat Commit Konvensional di GitHub](screenshots/Commits.jpg)

   **Penjelasan Singkat**:
   Commit dengan hash `57c44d5` berhasil di-push ke branch `feat/announcements-validation`. Pesan commit mengikuti standar industri `feat(announcements): validasi judul kosong + test` yang secara presisi menjelaskan tipe perubahan (`feat`), cakupan modul (`announcements`), aksi yang dilakukan (validasi judul kosong), dan kelengkapan bukti pengujian (`+ test`). Branch `main` dan `develop` tetap terlindungi dan steril dari perubahan langsung.

3. **Tabel Perbaikan Pesan Commit (Simulasi Sebelum & Sesudah)**:

| Hash Commit Lama | Pesan Commit Lama | Usulan Pesan Konvensional (Conventional Commit) | Alasan Perbaikan |
|---|---|---|---|
| `f6c0202` | `fix week 7 no sqflite` | `fix(announcements): replace sqflite dependency with in-memory mock repository` | Format lama ambigu dan tidak menyebutkan scope. Format baru memperjelas komponen yang diperbaiki (`announcements`) serta solusi teknis yang diterapkan. |
| `ad8a7d6` | `week 7 : Presentation, DI, dan verifikasi` | `feat(presentation): implement clean architecture ui and riverpod di wiring` | Format lama hanya menyalin judul modul. Format baru menggunakan tipe `feat(presentation)` dengan penjelasan teknis penambahan UI dan DI wiring. |
| `b23ea1d` | `week 7 : Domain dan data per fitur` | `feat(domain,data): define pure entities, repository contracts and dto models` | Format lama tidak mendeskripsikan artefak teknis. Format baru memperjelas komponen domain (entity, contract) dan data (model DTO) yang dibuat. |

---

### Praktikum 2 — PR dan peer review

1. **Format Pull Request**:
   - **Judul**: `feat(scope): deskripsi singkat`
   - **Masalah**: 
   - **Solusi**: 
   - **Cara Uji**: 
   - **Issue Reference**: `Closes #`

   <!-- Screenshot halaman Pull Request di GitHub / Git Provider -->
   ![Pull Request](screenshots/pull_request.png)

2. **Hasil Peer Review (Review Sejawat)**:
   - **Reviewer**: 
   - **Temuan Kebenaran (Logic / Bug / Edge Case)**: 
   - **Temuan Arsitektur (Clean Architecture / Dependency Rule)**: 
   - **Temuan Test & Keterbacaan**: 
   - **Keputusan Akhir**: `Approve` / `Request changes`

3. **Tindak Lanjut & Merge**:
   <!-- Catat hasil revisi dan proses merge branch -->

---

### Praktikum 3 — Static analysis dan mid review

1. **Pemeriksaan Mesin (Clean Checks)**:
   - `flutter analyze`
   - `dart format --set-exit-if-changed .`
   - `flutter test`

   <!-- Screenshot / Bukti eksekusi pemeriksaan mesin -->
   ![Hasil static analysis dan test](screenshots/ci_checks.png)

2. **Konfigurasi Continuous Integration (CI)**:
   <!-- Tautan atau ringkasan file .github/workflows/ci.yml -->

3. **Status Kesiapan Tengah Semester**:
   <!-- Ringkasan evaluasi kesiapan proyek tengah semester -->

---

## AI Challenge

### AI Prompt Challenge

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

<!-- Screenshot hasil review AI -->
![AI Code Review](screenshots/ai_review.png)

### AI Verification Checklist

1. Apakah temuan AI benar-benar ada dan terbukti (via grep, failure test, atau reproduksi manual)?
2. Apakah usulan AI melanggar *dependency rule* (misal domain mengimpor framework Flutter / Dio / SQLite)?
3. Apakah AI hanya melakukan *nitpick style* yang seharusnya ditangani formatter otomatis?
4. Minimal 2 temuan AI terbukti benar dengan bukti, dan minimal 1 temuan ditolak dengan alasan teknis tertulis.
5. Keputusan final dan alasan teknis Anda dicatat secara transparan.

jawab :

- **Temuan AI yang Diterima (Minimal 2)**:
  1. 
  2. 

- **Temuan AI yang Ditolak (Minimal 1)**:
  1. 

- **Tabel Komparasi: Usulan AI vs Keputusan Final Mahasiswa**:

| Temuan AI | Level | Rekomendasi AI | Keputusan Mahasiswa | Alasan & Argumen Teknis |
|---|:---:|---|:---:|---|
| Temuan 1 | | | Diterima / Ditolak | |
| Temuan 2 | | | Diterima / Ditolak | |
| Temuan 3 | | | Diterima / Ditolak | |

Dokumentasi lengkap tersimpan di [docs/](./docs).

---

## Refactoring dan testing

### Refactoring Challenge

1. **Tindak Lanjut Review Sejawat**: Menyesuaikan kode berdasarkan komentar *request changes* hingga mendapatkan status *approve*.
2. **Otomatisasi Style Formatting**: Memastikan seluruh berkas dirapikan dengan `dart format` sehingga review kode terbebas dari perdebatan spasi/style.
3. **Pemisahan PR Terfokus**: Memastikan setiap PR berukuran kecil (< 300 baris perubahan) dan fokus pada satu tanggung jawab fitur.

### Testing

- `flutter analyze`
- `flutter test`

jawab :

<!-- Screenshot hasil analyze dan test akhir -->
![Hasil Testing](screenshots/testing_final.png)

---

# Tugas, refleksi, dan referensi

## Mini Project / Industry Challenge — Mid-Project Review & Code Review

### 1. Status Paruh Semester & Peta Issue / PR
- **Proyek yang Direview**: `campus_notify` (Clean Architecture)
- **Tautan Issue**: `#`
- **Tautan Pull Request**: `#`
- **Cabang (Branch)**: `feature/...` $\rightarrow$ `develop`

### 2. Fitur Utama Proyek
1. 
2. 
3. 

### 3. Stack Teknologi
- **Framework**: Flutter SDK (Dart 3.x)
- **Architecture**: Clean Architecture (Feature-First: Domain, Data, Presentation)
- **State Management**: Flutter Riverpod
- **Routing**: GoRouter
- **Local Storage & Security**: `flutter_secure_storage`
- **HTTP Client**: Dio
- **Automation / CI**: GitHub Actions (`flutter analyze`, `flutter test`)

### 4. Cara Menjalankan
1. Clone repository dan checkout ke branch `develop`:
   ```bash
   git checkout develop
   ```
2. Masuk ke direktori proyek dan pasang dependensi:
   ```bash
   cd 07-week-7-clean-architecture/campus_notify
   flutter pub get
   ```
3. Jalankan pengujian statis dan unit test:
   ```bash
   flutter analyze
   flutter test
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

### 5. Hasil yang Dicapai
- 
- 
- 

---

## Refleksi

1. Apa beda LGTM ("Looks Good To Me") buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?

jawab : 

2. Kapan komentar review wajib berstatus request changes, dan kapan cukup sekadar saran (comment / nitpick)?

jawab : 

3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?

jawab : 

4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya terhadap kualitas aplikasi?

jawab : 

---

## Referensi Pendukung

- [Slide Week 8: Mid Project Review & Code Review](https://jti-polinema.github.io/flutter-codelab/00-slides/Week_08_Mid_Project_Review_Code_Review.html)
- [Atlassian: GitFlow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [GitHub: About Pull Request Reviews](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/about-pull-request-reviews)
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Flutter: Static Analysis & Linter Rules](https://docs.flutter.dev/tools/using-ide)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
