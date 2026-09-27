# 05-week-5-local-storage-offline-first
- Tujuan pembelajaran minggu ini adalah diharapkan mampu :
- menjelaskan perbedaan penyimpanan key-value, relasional, dan NoSQL di perangkat;
- menyimpan preferensi sederhana (tema, terakhir dibuka) dengan SharedPreferences;
- menerapkan CRUD catatan dengan SQLite (sqflite) melalui repository lokal;
- menerapkan pola offline-first: cache-first read, dirty flag, dan antrean sinkronisasi;
- menampilkan state loading, error, empty, dan success untuk data lokal dengan Riverpod;
- menguji repository lokal dengan repository palsu (tanpa database sungguhan).

# Konsep local storage dan offline-first
pada praktikum ini menjelasakan tentang Jenis penyimpanan lokal , yaitu sebagai contoh :
SharedPreferences,SQLite via sqflite ,Hive,Drift

konsep yang digunakan adalah Offline-first, bukan offline-only
menggunakan 3 mekanisme  :
- Cache-first read: tampilkan data lokal seketika, lalu refresh dari jaringan di background dan simpan hasilnya.
- Dirty flag: setiap perubahan lokal yang belum terkirim ditandai (dirty = 1) agar bisa di-sync belakangan.
- Antrean sinkronisasi: operasi tertunda diproses berurutan saat online; konflik diselesaikan dengan aturan eksplisit (misalnya last-write-wins berdasarkan updated_at).

UI (ConsumerWidget) --watch--> Provider (AsyncValue)
Provider --panggil--> LocalRepository --CRUD--> SQLite
LocalRepository --sync--> Remote (simulasi) --sukses--> dirty = 0
Cache: baca lokal dulu, refresh background, simpan



# Praktikum 1: SharedPreferences

menambahkan lib/data/prefs.dart dan lib/pages/settings_page.dart untuk penyambungan minimal dengan riverpod

# Praktikum 2: SQLite dan repository catatan

menambahkan lib/data/local/note.dart dengan field dirty untuk catatan yang belum sinkron.
menambahkan lib/data/local/db.dart sebagai pembuka database untuk sql lite.
menambahahkan lib/data/repositories/note_repository.dart Repository sebagai satu-satunya pintu data
dan juga halaman offline pada notes_pages.dart

# Praktikum 3: Cache-first dan antrean sync

menambahkan Cache-first read untuk data API dengan endpoint GET /posts JSONPlaceholder,

menambahkan sinkronisasi dirty/ catatan kotor dengan menambahkan delay pada server dengan begitu server harus menunggu sync agar data tidak diry 

Simulasi offline yang deterministik dengan hasil dibawah berikut

# hasil praktikum 1,2 3
 #simulasi offline

### page awal notes

![kosong](screenshots\belum_ada_catatan.jpg)

### membuat catatan baru
![buat_catatan_baru](screenshots\tambah_catatan.jpg)

### setelah dibuat 

![hasil](screenshots\hasil_tambah.jpg)


### membuat notes lainnya 
![datalain](screenshots\data_lain.jpg)


### Test dengan menambahkan button paksa offline

![offline](screenshots\paksa_offline.jpg)

### Test dengan mematikan button pakasa offline yang membuat status nya online dengan sinkronisasi yang berjalan

![online](screenshots\sinkron_online.jpg)



#  AI Challenge

prompt : 

Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
- Jelaskan trade-off setiap pilihan.


Berikut jawaban untuk AI Challenge:

| Pilihan | Kompleksitas query dan relasi | Stream | Type-safety | Boilerplate dan testing | Rekomendasi |
|---|---|---|---|---|---|
| **SharedPreferences** | Key-value sederhana; tidak cocok untuk query atau relasi catatan | Tidak ditujukan untuk mengamati perubahan koleksi | Tipe dasar tersedia, tetapi tidak memvalidasi struktur objek | Paling sedikit; mudah diuji dengan mock | **Preferensi tema** dan nilai sederhana lain |
| **Hive** | Baca/tulis berdasarkan key mudah; query kompleks dan relasi perlu dikelola sendiri | Dapat memantau perubahan box, tergantung paket/versi | Model bertipe mungkin memerlukan adapter/generator | Boilerplate rendah–sedang; box sementara dapat dipakai untuk test | Catatan sederhana jika query/relasi terbatas |
| **sqflite (SQLite)** | SQL lengkap: filter, urut, indeks, dan relasi | Tidak menyediakan stream query secara langsung | Mapping dari `Map` dan validasinya ditangani manual | Boilerplate sedang; dapat diuji memakai database sementara atau repository palsu | **Catatan untuk proyek saat ini**, karena sudah dipakai |
| **Drift** | SQL dengan API Dart terstruktur; relasi didukung | Mendukung stream query melalui `watch` | Kuat, dengan tipe dan kode hasil generator | Setup awal lebih banyak; mendukung database sementara untuk test | **Catatan jika aplikasi membutuhkan query bertipe dan UI reaktif** |

**Skema SQLite untuk catatan**

```text
┌─────────────────────────────────────────┐
│ notes                                   │
├─────────────────────────────────────────┤
│ id          INTEGER  PRIMARY KEY        │
│ title       TEXT     NOT NULL           │
│ body        TEXT     NOT NULL           │
│ created_at  TEXT     NOT NULL           │
│ updated_at  TEXT     NOT NULL           │
│ dirty       INTEGER  NOT NULL DEFAULT 1 │
└─────────────────────────────────────────┘
```

```sql
CREATE INDEX notes_updated_at_idx ON notes(updated_at);
CREATE INDEX notes_dirty_idx ON notes(dirty);
```

Untuk lebih dari 1000 catatan, SQLite sesuai. Indeks membantu pencarian berdasarkan waktu dan status sync; daftar sebaiknya dimuat bertahap dengan `LIMIT` dan `OFFSET`, bukan seluruhnya sekaligus.

**Trade-off:** SharedPreferences paling sederhana, tetapi tidak cocok untuk koleksi catatan. Hive praktis untuk data sederhana, tetapi query dan relasi lebih manual. sqflite memberi kendali SQL dengan biaya mapping dan pengelolaan stream yang lebih manual. Drift menambah setup generator, tetapi memberi type-safety dan stream query. Untuk proyek ini, pilihan praktisnya adalah **SharedPreferences untuk tema dan sqflite untuk catatan**; Drift dapat dipertimbangkan jika kebutuhan query atau reaktivitas berkembang.


model : chatgpt 6-luna


# AI Verification Checklist

- [x] Apakah AI menempatkan daftar catatan di SharedPreferences? Tidak. SharedPreferences direkomendasikan hanya untuk preferensi sederhana seperti tema; daftar catatan disimpan di database.
- [x] Apakah skema AI mendukung antrean sync (`dirty` / `updated_at`) atau hanya CRUD polos? Mendukung dasar antrean sync: skema catatan yang ada memiliki `dirty` dan `updated_at`. Namun, implementasi sinkronisasi proyek saat ini masih simulasi lokal; belum ada outbox persisten atau pengiriman ke server.
- [x] Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi? Stream didukung Drift melalui query `watch`, tetapi rekomendasi tersebut bukan klaim bahwa implementasi proyek sekarang real-time. Proyek saat ini memakai sqflite dan memuat ulang data secara eksplisit setelah operasi.
- [-] Apakah estimasi boilerplate AI masuk akal setelah Anda mencoba instalasinya (`flutter pub add` + migrasi skema)? Belum diverifikasi dengan instalasi/migrasi Drift. `pubspec.yaml` saat ini memakai `sqflite`, bukan Drift; perlu mencoba setup generator, skema, dan migrasi sebelum memberi penilaian empiris.
- [x] Keputusan final: gunakan SharedPreferences untuk preferensi tema dan Drift untuk catatan bila kebutuhan query bertipe dan stream reaktif membenarkan setup generator. Untuk implementasi praktikum saat ini, tetap memakai sqflite adalah pilihan pragmatis karena sudah terpasang dan skema/repository sudah ada; Drift belum diinstal atau diuji.

note : Belum dapat diverifikasi. Proyek ini memakai sqflite dan saya belum mencoba memasang Drift, membuat skema, atau menjalankan migrasi. Jadi, saya belum bisa memastikan apakah estimasi boilerplate dari AI sesuai praktik.

jawaban : 
- Daftar catatan di SharedPreferences? 
Tidak. SharedPreferences hanya untuk nilai sederhana seperti preferensi tema. Catatan disimpan di database karena berbentuk kumpulan data yang perlu ditambah, dibaca, diubah, dan dihapus.
- Skema mendukung antrean sync?
 Sebagian. dirty menandai catatan yang belum tersinkron, sementara updated_at mencatat waktu perubahannya. Namun, ini baru dasar untuk antrean; proyek belum memiliki outbox persisten atau pengiriman data ke server.
- Klaim real-time didukung stream? Untuk Drift, ya; untuk aplikasi ini,
 belum. Drift menyediakan query watch yang dapat memberi tahu UI saat data berubah. Implementasi proyek saat ini memakai sqflite dan memuat ulang data secara eksplisit setelah operasi, jadi belum menggunakan stream.
- Apakah boilerplate Drift sudah diuji? 
Belum. Drift belum dipasang di pubspec.yaml, dan proses instalasi, generator, serta migrasi skemanya belum dicoba. Karena itu, belum bisa memastikan estimasi boilerplate berdasarkan pengalaman langsung pada proyek ini.
- Keputusan akhir: gunakan SharedPreferences untuk preferensi tema. Untuk catatan, Drift cocok jika aplikasi membutuhkan query bertipe dan stream reaktif; tetapi untuk praktikum yang sekarang sudah memakai sqflite, tetap gunakan sqflite agar tidak perlu migrasi tanpa kebutuhan yang jelas.

# Refactoring Challenge

## Perubahan dan Status

1. **Ekstraksi `NoteTile` — selesai.** Baris catatan dipisahkan ke `lib/widgets/note_tile.dart` dan digunakan oleh `NotesPage`. Widget menampilkan badge "Belum tersinkron" saat `note.dirty == true`; callback hapus tetap ditangani halaman daftar.

2. **Pemisahan logika sync — sebagian selesai.** Fungsi `syncNotes` sudah berada di `lib/data/sync.dart`, terpisah dari `NoteRepository`. Namun, alur cache posts masih berada di `PostRepository`/`PostsNotifier` dan belum dipindahkan seluruhnya ke `sync.dart`.

3. **Detail catatan dengan GoRouter — belum selesai.** Dependency `go_router` sudah ditambahkan dan `NoteRepository.fetchNoteById()` tersedia. Route `/note/:id`, halaman detail, serta navigasi dari `NoteTile` belum diimplementasikan.

## Hasil Test

Perintah: `flutter test test/note_test.dart test/widget_test.dart`

Hasil terakhir: **8 test lulus, 0 gagal.** Test mencakup parsing/serialisasi model, provider catatan dengan repository palsu, dan widget yang saat ini diuji. Hasil ini belum memverifikasi route detail atau pemindahan penuh alur cache posts karena kedua bagian tersebut belum selesai.



# Tugas, refleksi, dan referensi

## Mini project / Industry Challenge

1. Preferensi: toggle tema gelap/terang + waktu terakhir dibuka via SharedPreferences.
CRUD catatan persisten via SQLite (sqflite) melalui repository lokal + Riverpod; daftar diurutkan updated_at terbaru.
2. Offline-first: cache-first untuk data bacaan, dirty flag + syncNotes untuk tulisan, dan aturan konflik eksplisit yang didokumentasikan.
Buktikan mode pesawat: screenshot daftar catatan saat offline dan badge dirty sebelum/sesudah sync.
3. Sertakan minimal 2 test yang lulus (1 unit test model + 1 test provider dengan repository palsu).
4. Kerjakan bagian AI Challenge dan dokumentasikan prompt, tabel perbandingan storage, keputusan final, serta alasan teknis Anda di docs/.
5. Push ke repository portfolio pada folder 05-week-5-local-storage-offline-first/ dengan struktur lib/, test/, docs/, README.md, dan screenshots/. README menjelaskan tujuan, fitur utama, stack teknologi, cara menjalankan, dan hasil yang dicapai.

## Refleksi

1. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?

jawab : SharedPreferences dirancang untuk pasangan key-value sederhana, seperti pilihan tema atau bahasa, bukan koleksi catatan. Jika seluruh daftar disimpan sebagai satu nilai SharedPreferences, aplikasi harus mengelola serialisasi dan menulis ulang koleksi untuk perubahan kecil; query SQLite dan pembaruan per catatan juga tidak bisa digunakan langsung.


2. Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain (misalnya network-first untuk data harga real-time)?

jawab : Cache-first dipakai saat data lama masih berguna dan aplikasi perlu cepat dibuka. Kalau data harus selalu terbaru, seperti harga, ambil dari jaringan dulu.

3. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah (tabel outbox) menjadi perlu?

jawab : dirty menandai catatan yang belum disinkronkan. Di proyek ini, sinkronisasi masih simulasi; belum benar-benar mengirim ke server. Tabel outbox diperlukan jika aplikasi harus menyimpan dan mencoba ulang banyak operasi sync.

4. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?

jawab : Dari implementasi yang ada, keputusan yang dapat dinyatakan adalah belum memakai Drift; proyek memakai sqflite. Alasannya, penyimpanan catatan sudah berjalan dengan repository SQLite yang ada
