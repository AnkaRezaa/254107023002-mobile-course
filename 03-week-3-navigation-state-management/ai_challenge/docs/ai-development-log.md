# Dokumentasi AI Challenge: StatsPage Riverpod

## 1. Prompt yang Digunakan

Prompt awal yang digunakan:

> Buatkan halaman Flutter bernama StatsPage menggunakan flutter_riverpod.
> Requirements:
> - ConsumerWidget dengan satu AsyncNotifierProvider yang mensimulasikan pengambilan data statistik (delay 2 detik, kadang gagal 30%).
> - UI harus menangani loading (spinner), error (pesan + tombol retry), dan success (ListView 3 item).
> - Berikan unit test untuk notifier-nya.
> Jelaskan setiap bagian kode dalam komentar.

Prompt lanjutan untuk pemeriksaan kualitas:

> Apakah state diubah secara immutable (tidak ada state.add() atau mutasi list langsung)?
> Apakah ref.watch hanya dipakai di dalam build, dan ref.read di callback?
> Apakah ketiga state AsyncValue benar-benar ditangani (bukan hanya success)?
> Apakah provider dideklarasikan dengan tipe eksplisit dan tidak duplikat dengan provider lain?
> Apakah kode AI memakai API Riverpod versi lama (StateProvider antipattern, StateNotifierProvider usang, atau Consumer bertingkat yang tidak perlu)? Perbaiki ke pola Notifier/ConsumerWidget.
> Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?

## 2. Output Awal AI

Output awal membuat aplikasi counter template Flutter diganti menjadi aplikasi statistik. Komponen utamanya adalah:

- Model `Statistic` dengan `label` dan `value`.
- `StatisticsNotifier` berbasis `AsyncNotifier<List<Statistic>>`.
- `statisticsProvider` berbasis `AsyncNotifierProvider`.
- Simulasi request dengan delay dua detik dan peluang error 30%.
- `StatsPage` berbasis `ConsumerWidget`.
- UI loading, error dengan tombol `Retry`, dan success berupa tiga item `ListView`.
- Dua unit test untuk kondisi berhasil dan gagal.

Output awal sempat memiliki masalah teknis saat penggabungan patch: sebagian template counter lama masih tertinggal di `main.dart`, sehingga muncul error sintaks dan simbol tidak ditemukan. Masalah itu diperbaiki sebelum validasi akhir.

## 3. Perbaikan yang Dilakukan

### Perbaikan implementasi

1. Membersihkan sisa kode counter lama dari `lib/main.dart` agar hanya tersisa satu `main()` dan satu implementasi aplikasi.
2. Menambahkan dependency `flutter_riverpod` pada `pubspec.yaml`.
3. Menggunakan `AsyncNotifier<List<Statistic>>` agar state async dikelola oleh Riverpod modern.
4. Menggunakan `Random().nextDouble() < 0.3` agar peluang gagal benar-benar 30%.
5. Menambahkan `ProviderScope` pada root aplikasi agar provider dapat digunakan.
6. Menempatkan `ref.watch(statisticsProvider)` di dalam `StatsPage.build`.
7. Menempatkan `ref.read(statisticsProvider.notifier).retry()` hanya pada callback tombol Retry.
8. Menangani `loading`, `error`, dan `data` dengan `AsyncValue.when`.
9. Menggunakan `AsyncValue.guard(fetcher)` pada `retry()` sehingga hasil retry menjadi state sukses atau error tanpa mutasi list langsung.
10. Menggunakan override `fetcher` pada unit test agar test cepat dan tidak bergantung pada delay maupun angka acak.

### Perbaikan testing

Test pertama memverifikasi bahwa notifier menghasilkan tiga statistik ketika request berhasil. Test kedua memverifikasi bahwa error request diteruskan sebagai exception. `ProviderContainer` dibuang melalui `addTearDown` agar resource test tidak bocor.

## 4. Peta Kode untuk Demo

File utama: `lib/main.dart`

| Bagian | Baris | Penjelasan |
|---|---:|---|
| Import | 1-4 | Mengimpor random, Flutter Material, dan Riverpod. |
| Model `Statistic` | 6-12 | Menyimpan label dan nilai satu statistik. Field bersifat `final`. |
| `StatisticsFetcher` | 14-15 | Tipe fungsi untuk sumber data yang bisa diganti ketika testing. |
| `StatisticsNotifier` | 17-30 | Mengelola request async dan aksi retry. `build()` menjalankan fetcher. |
| `statisticsProvider` | 32-36 | Provider tunggal dengan tipe eksplisit `List<Statistic>`. |
| `_fetchStatistics` | 38-49 | Delay dua detik, error 30%, lalu mengembalikan tiga data statistik. |
| `main()` | 51-53 | Membungkus aplikasi dengan `ProviderScope`. |
| `MyApp` | 55-69 | Menyediakan tema dan membuka `StatsPage`. |
| `StatsPage` | 71-112 | `ConsumerWidget` yang membaca provider dan membangun UI. |
| Loading | 82-83 | Menampilkan `CircularProgressIndicator`. |
| Error | 84-89 | Menampilkan pesan error dan tombol Retry. |
| Success | 90-108 | Menampilkan data menggunakan `ListView.builder`. |
| `_ErrorView` | 114-134 | Widget terpisah untuk tampilan error. |

File test: `test/widget_test.dart`

| Bagian | Baris | Penjelasan |
|---|---:|---|
| Test sukses | 14-39 | Meng-override fetcher dengan tiga data tetap dan memeriksa hasilnya. |
| Test error | 41-59 | Meng-override fetcher agar gagal dan memeriksa exception. |

## 5. Hasil Testing

Perintah yang dijalankan dari folder `ai_challenge`:

```text
flutter pub get
flutter analyze
flutter test
```

Hasil akhir:

```text
flutter analyze: No issues found!
flutter test: All tests passed! (2 tests)
```

## 6. Checklist Tanggung Jawab Teknis

- [x] Prompt disimpan.
- [x] Output awal AI didokumentasikan.
- [x] Perbaikan yang dilakukan didokumentasikan.
- [x] Hasil testing disimpan.
- [x] Peta kode per bagian tersedia untuk penjelasan saat demo.
- [x] Tidak ada `state.add()` atau mutasi list langsung.
- [x] `ref.watch` hanya digunakan di `build` dan `ref.read` pada callback.
- [x] Loading, error, dan success ditangani.
- [x] Tidak memakai `StateProvider`, `StateNotifierProvider`, atau `Consumer` bertingkat yang tidak diperlukan.
