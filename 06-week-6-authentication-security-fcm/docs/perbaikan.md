# Dokumentasi Teknis: AI Prompt Challenge & Perbaikan Manual

Dokumen ini berisi pencatatan evaluasi mandiri terhadap kode yang dihasilkan oleh AI coding assistant, daftar perbaikan yang dilakukan secara manual, tabel hasil uji tiga app state, serta panduan penguasaan konsep Lifecycle Token FCM untuk persiapan demo praktikum.

---

## 1. Daftar Perbaikan Manual (Manual Fixes Applied)

Meskipun draf awal AI sudah mencakup arsitektur dasar, terdapat beberapa perbaikan manual yang wajib dilakukan agar kode memenuhi standar *clean code*, mematuhi pembaruan library terbaru, dan menjaga keamanan data:

### A. Perbaikan Linter Dart (`prefer_initializing_formals`)
* **Masalah:** Draf awal AI menulis konstruktor dengan *assignment initializer list*:
  ```dart
  PushService({
    required Dio dio,
    required void Function(String route) onNavigate,
  }) : _dio = dio, _onNavigate = onNavigate;
  ```
* **Perbaikan:** Disesuaikan menggunakan *initializing formals* standar Dart modern:
  ```dart
  PushService({
    required this.dio,
    required this.onNavigate,
    this.onTokenReceived,
  });
  ```

### B. Penyesuaian API `flutter_local_notifications` Versi 22+
* **Masalah:** Pada library `flutter_local_notifications: ^22.3.1`, method `.show()` tidak lagi menerima parameter posisional (*positional arguments*). Jika tidak memakai nama parameter, compiler akan melempar error: `Too many positional arguments: 0 allowed, but 4 found`.
* **Perbaikan:** Menambahkan label *named arguments* secara eksplisit:
  ```dart
  await _localNotifications.show(
    id: message.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: notificationDetails,
    payload: route,
  );
  ```

### C. Keamanan & Sensor Token (*Token Masking*)
* **Masalah:** AI mencetak token FCM secara penuh ke terminal console melalui `debugPrint('[FCM] Token Perangkat: $token')`. Hal ini melanggar pedoman privasi dan keamanan laporan.
* **Perbaikan:** Menambahkan logika *string masking* (hanya mengambil 12 karakter pertama):
  ```dart
  final masked = token.length > 12 ? '${token.substring(0, 12)}...' : token;
  debugPrint('[FCM] Token Perangkat (Masked): $masked');
  ```

### D. Integrasi State Management (Riverpod) untuk Tampilan UI
* **Masalah:** Draf AI hanya mengirimkan token ke backend tanpa menyediakan saluran untuk menampilkan token ke halaman Debug (`HomePage`).
* **Perbaikan:** Menambahkan callback `onTokenReceived` pada kelas `PushService` dan menyambungkannya ke `fcmTokenProvider` di `main.dart`:
  ```dart
  onTokenReceived: (token) {
    ref.read(fcmTokenProvider.notifier).setToken(token);
  },
  ```

### E. Penanganan Siklus Render Flutter (*Safe Initialization*)
* **Masalah:** Memanggil inisialisasi asinkron langsung di `initState()` dapat memicu konflik saat widget tree sedang me-mount.
* **Perbaikan:** Membungkus pemanggilan inisialisasi dengan `WidgetsBinding.instance.addPostFrameCallback`:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(pushServiceProvider).initialize();
  });
  ```

---

## 2. AI Verification Checklist

| Kriteria Pemeriksaan | Status | Catatan Teknis Evaluasi |
| :--- | :---: | :--- |
| **Background handler top-level dengan `@pragma('vm:entry-point')`** | ✅ **Lulus** | Berada di luar kelas (top-level) agar Dart VM tidak membuang fungsi ini saat kompilasi rilis (*tree-shaking*). |
| **`onTokenRefresh` mengirim token baru ke backend** | ✅ **Lulus** | Event stream memanggil `sendTokenToBackend(newToken)` via `dio.post('/devices')`, bukan sekadar mencetak log. |
| **Foreground memakai local notification manual** | ✅ **Lulus** | Android tidak memunculkan banner status bar saat foreground, sehingga `_localNotifications.show()` wajib dipanggil manual. |
| **Navigasi ketiga state masuk ke rute yang benar** | ✅ **Lulus** | Payload data `route` berhasil diteruskan ke GoRouter (`_onNavigate`) pada semua skenario. |
| **Token/secret tidak di-hardcode & tidak di-log penuh** | ✅ **Lulus** | Kredensial Firebase tersimpan di `google-services.json` dan pencetakan token di terminal telah disensor. |

---

## 3. Tabel Hasil Uji Tiga App State

Pengujian dilakukan menggunakan perangkat fisik Android dengan payload custom data: `{"route": "/pengumuman/3", "id": "3"}`.

| State Aplikasi | Aksi Pengujian | Perilaku yang Diharapkan 
| :--- | :--- | :--- | :--- | :--- |
| **Foreground** | Aplikasi sedang dibuka dan aktif di layar depan. Kirim pesan dari console. | Banner lokal pop-up di layar atas, saat diklik membuka halaman Pengumuman #3. | Sesuai. Banner lokal muncul dan navigasi ke `/pengumuman/3` berhasil. | `screenshots/foreground.gif` |
| **Background** | Aplikasi di-minimize (tekan tombol Home). Kirim pesan dari console. | Banner notifikasi sistem muncul, saat diklik membuka Pengumuman #3. | Sesuai. Notifikasi sistem muncul dan auto-redirect ke `/pengumuman/3`. | `screenshots/background.gif` |
| **Terminated** | Aplikasi ditutup paksa (*swipe kill* dari Recent Apps). Kirim pesan. | Notifikasi sistem muncul, diklik -> aplikasi start dari awal ke Pengumuman #3. | Sesuai. `getInitialMessage()` menangkap payload dan merutekan layar ke `/pengumuman/3`. | `screenshots/terminater.gif` |

---

## 4. Materi Penguasaan Konsep: Lifecycle Token FCM (Persiapan Demo)

Gunakan poin-poin berikut sebagai bahan penjelasan lisan saat asistensi/demo tanpa melihat teks catatan:

1. **Pembuatan Token Pertama Kali (`getToken`):**
   * Saat aplikasi pertama kali dijalankan dan Firebase diinisialisasi, library menghubungi server FCM Google untuk meregistrasikan ID unik perangkat fisik.
   * Token ini berfungsi seperti "alamat IP" atau "nomor telepon" unik perangkat di jaringan Google Cloud Messaging.

2. **Pengiriman ke Backend (`sendTokenToBackend`):**
   * Backend kampus perlu memetakan token ini dengan `user_id` mahasiswa yang sedang login (disimpan ke database tabel `user_devices`).
   * Tanpa pengiriman token ke backend, server kampus tidak akan pernah bisa mengirimkan notifikasi personal (seperti nilai atau tagihan).

3. **Rotasi & Pembaruan Token (`onTokenRefresh`):**
   * Token FCM **tidak bersifat permanen**. Token dapat berganti secara otomatis ketika:
     1. Aplikasi di-uninstall lalu di-install ulang.
     2. Pengguna melakukan *Clear Data / Clear Storage* di pengaturan HP.
     3. Pemulihan cadangan data (*backup restore*) ke perangkat baru.
     4. Google melakukan rotasi berkala demi alasan keamanan.
   * Listener `onTokenRefresh` wajib aktif terus-menerus agar saat token berganti, token baru langsung dikirimkan ke server backend untuk menimpa token lama. Jika tidak, notifikasi selanjutnya akan gagal (*Unregistered Device*).

4. **Perbedaan Pesan Bertarget Topik vs Token Perangkat:**
   * **Topik (`Topic`):** Digunakan untuk pesan massal (*broadcast*), misalnya seluruh mahasiswa kampus (`pengumuman-kampus`) atau satu angkatan. Server cukup mengirim 1 pesan ke topik tersebut, Google yang mendistribusikannya ke semua subscriber.
   * **Token Perangkat:** Digunakan untuk pesan privat/personal khusus satu pengguna (misal: "KRS Anda telah disetujui", "Pembayaran SPP berhasil").

5. **Mengapa Background Isolate Tidak Boleh Mengakses `BuildContext`?**
   * `firebaseMessagingBackgroundHandler` dieksekusi di *Dart isolate* yang terpisah dari mesin UI utama. Di isolate ini tidak ada Widget Tree, tidak ada konteks render, dan tidak ada Theme/Navigator. Mengakses `BuildContext` atau mencoba menampilkan dialog di sini pasti menyebabkan aplikasi mengalami *crash* seketika.
