# Dokumentasi Pengembangan Berbantuan AI

## Tugas

Membuat repository layer Flutter untuk endpoint:

```text
GET /comments?postId={id}
```

Teknologi yang digunakan adalah Dio dan flutter_riverpod.

## 1. Prompt yang Digunakan

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
 dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

## 2. Output Awal AI

Output awal menghasilkan empat bagian utama:

1. Model `Comment` di `lib/data/models/comment.dart`.
2. Repository `CommentRepository` di `lib/data/repositories/comment_repository.dart`.
3. Provider komentar dan helper pesan error di `lib/data/comments_provider.dart`.
4. Unit test `Comment.fromJson` di `test/comment_test.dart`.

Output awal sudah memisahkan UI, provider, repository, dan model. Namun, bentuk
provider family perlu disesuaikan dengan API Riverpod yang tersedia di proyek ini.
Selain itu, test widget bawaan Flutter masih menguji counter lama dan melakukan
request jaringan ketika aplikasi sudah berubah menjadi halaman pagination.

## 3. Perbaikan yang Dilakukan

### Penyesuaian provider Riverpod

`FamilyAsyncNotifier` tidak tersedia pada versi Riverpod proyek ini. Provider
disesuaikan menjadi `AsyncNotifier` dengan `postId` yang diterima melalui
constructor, lalu didaftarkan dengan `AsyncNotifierProvider.family`.

Hasil pemakaian provider tetap sederhana:

```dart
final comments = ref.watch(commentsProvider(1));
```

### Sentralisasi konfigurasi HTTP

`baseUrl`, `connectTimeout`, dan `receiveTimeout` dipertahankan di
`lib/data/api_client.dart`. Timeout yang sempat ditulis ulang pada repository
dihapus agar konfigurasi tidak tersebar.

### Perbaikan test widget

`test/widget_test.dart` masih merupakan test counter bawaan Flutter. Test tersebut
diganti menjadi smoke test untuk `PagedPostPage`, dibungkus `ProviderScope`, dan
menggunakan fake notifier agar test tidak memanggil API sungguhan.

### Kompatibilitas repository post

`providers.dart` lama masih mengompilasi pemanggilan `fetchPosts()`. Method ini
dipertahankan di `PostRepository` bersama `fetchPostsPage()` agar fitur post lama
dan pagination dapat dikompilasi bersamaan.

## 4. Penjelasan Kode untuk Demo

### `lib/data/models/comment.dart`

- `class Comment` adalah model data untuk satu komentar API.
- Constructor `const` membuat objek immutable.
- `postId` dan `id` bertipe `int`.
- `name`, `email`, dan `body` bertipe `String`.
- `Comment.fromJson` mengubah map JSON menjadi object Dart.
- `(json['postId'] as num?)?.toInt() ?? 0` aman ketika field hilang, null, atau berupa integer/double.
- `json['name'] as String? ?? ''` mencegah nilai null masuk ke field non-nullable.

### `lib/data/repositories/comment_repository.dart`

- Repository menjadi satu-satunya layer yang melakukan request Dio untuk komentar.
- `_dio` diterima melalui constructor agar dependency dapat diganti saat test.
- `fetchComments(int postId)` menerima ID post yang akan dicari.
- `get('/comments', queryParameters: {'postId': postId})` menghasilkan endpoint dengan query `postId`.
- `response.data ?? []` menangani response tanpa data.
- `whereType<Map<String, dynamic>>()` menyaring item yang bukan object JSON.
- `.map(Comment.fromJson)` mengubah setiap object JSON menjadi `Comment`.

### `lib/data/comments_provider.dart`

- `commentsDioProvider` menyediakan instance Dio dari client terpusat.
- `commentRepositoryProvider` menyuntikkan Dio ke `CommentRepository`.
- `CommentsNotifier` mengambil data asynchronous melalui repository.
- Exception dari `build()` diteruskan Riverpod menjadi `AsyncError`.
- `commentsProvider` memakai `.family` agar setiap `postId` mempunyai state sendiri.
- `friendlyCommentErrorMessage` mengubah error teknis menjadi pesan UI.
- Timeout, connection error, HTTP 404, dan HTTP 500 memiliki pesan khusus.

### `test/comment_test.dart`

- Test memanggil `Comment.fromJson({})` dengan map kosong.
- Kondisi ini mewakili response dengan semua field hilang.
- Test memastikan angka menjadi `0` dan teks menjadi string kosong.
- Test ini menguji edge case, bukan hanya JSON lengkap atau happy path.

### `test/widget_test.dart`

- `ProviderScope` menyediakan container Riverpod untuk widget.
- `FakePagedPostsNotifier` mencegah smoke test melakukan request HTTP nyata.
- Override provider membuat test deterministik dan tidak bergantung internet.
- Test memastikan judul `Posts Paged` tampil.

## 5. Hasil Testing

Perintah dijalankan dari folder `week4_api`:

```powershell
flutter analyze
```

Hasil:

```text
No issues found!
```

Perintah:

```powershell
flutter test
```

Hasil:

```text
All tests passed!
```

Test yang tervalidasi mencakup:

- `Comment.fromJson` dengan semua field hilang.
- Widget pagination dengan provider palsu tanpa request jaringan.

## 6. Kesimpulan Demo

Kode AI diterima setelah diperiksa dan diperbaiki. UI tidak memanggil Dio langsung,
parsing JSON aman terhadap field hilang, konfigurasi HTTP terpusat, error jaringan
memiliki pesan yang ramah pengguna, dan analyzer serta seluruh test berhasil.
