# 05-week-5-local-storage-offline-first


# Konsep local storage dan offline-first

# Praktikum 1: SharedPreferences

# Praktikum 2: SQLite dan repository catatan


# Praktikum 3: Cache-first dan antrean sync

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
Jelaskan trade-off setiap pilihan.


# AI Verification Checklist

- [x] Apakah AI menempatkan daftar catatan di SharedPreferences? Tidak. SharedPreferences direkomendasikan hanya untuk preferensi sederhana seperti tema; daftar catatan disimpan di database.
- [x] Apakah skema AI mendukung antrean sync (`dirty` / `updated_at`) atau hanya CRUD polos? Mendukung dasar antrean sync: skema catatan yang ada memiliki `dirty` dan `updated_at`. Namun, implementasi sinkronisasi proyek saat ini masih simulasi lokal; belum ada outbox persisten atau pengiriman ke server.
- [x] Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi? Stream didukung Drift melalui query `watch`, tetapi rekomendasi tersebut bukan klaim bahwa implementasi proyek sekarang real-time. Proyek saat ini memakai sqflite dan memuat ulang data secara eksplisit setelah operasi.
- [-] Apakah estimasi boilerplate AI masuk akal setelah Anda mencoba instalasinya (`flutter pub add` + migrasi skema)? Belum diverifikasi dengan instalasi/migrasi Drift. `pubspec.yaml` saat ini memakai `sqflite`, bukan Drift; perlu mencoba setup generator, skema, dan migrasi sebelum memberi penilaian empiris.
- [x] Keputusan final: gunakan SharedPreferences untuk preferensi tema dan Drift untuk catatan bila kebutuhan query bertipe dan stream reaktif membenarkan setup generator. Untuk implementasi praktikum saat ini, tetap memakai sqflite adalah pilihan pragmatis karena sudah terpasang dan skema/repository sudah ada; Drift belum diinstal atau diuji.


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

