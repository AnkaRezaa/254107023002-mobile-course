# Output Awal Usulan AI Coding Assistant (AI Proposal)

Dokumen ini berisi draf rekomendasi arsitektur perangkat lunak yang diusulkan oleh AI coding assistant untuk refactoring proyek **campus_notify** menuju **Feature-First Clean Architecture**.

---

## 1. Usulan Struktur Feature-First Clean Architecture (Auth + Announcements)

Sesuai prinsip *Clean Architecture* dan aturan dependensi (*Dependency Rule*), panah dependensi hanya mengarah ke dalam (Presentation -> Domain <- Data). Domain Layer berada di pusat tanpa dependensi ke framework luar atau implementasi data.

```text
lib/
├── core/                                   # Komponen & modul bersama lintas fitur
│   ├── failures.dart                       # Sealed class Failure domain murni Dart
│   ├── format.dart                         # Helper murni (masking token, pemformatan tanggal)
│   └── providers.dart                      # Provider global (apiClientProvider)
├── features/
│   ├── auth/                               # FITUR 1: Autentikasi Mahasiswa
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_session.dart       # Objek bisnis murni sesi login
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart    # Abstract interface kontrak repository
│   │   │   └── usecases/
│   │   │       └── login_usecase.dart      # Use case: validasi input & orkestrasi sesi
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── token_store.dart        # Local data source (FlutterSecureStorage)
│   │   │   ├── models/
│   │   │   │   └── auth_session_model.dart # DTO (toMap, fromMap, toEntity)
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart # Implementasi konkret AuthRepository
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_providers.dart     # Riverpod DI & AuthNotifier
│   │       └── pages/
│   │           └── login_page.dart         # UI Login bersih (steril dari Dio)
│   └── announcements/                      # FITUR 2: Pengumuman Kampus
│       ├── domain/
│       │   ├── entities/
│       │   │   └── announcement.dart       # Objek bisnis murni pengumuman
│       │   ├── repositories/
│       │   │   └── announcement_repository.dart # Abstract interface kontrak
│       │   └── usecases/
│       │       └── get_announcements.dart  # Use case ambil daftar pengumuman
│       ├── data/
│       │   ├── models/
│       │   │   └── announcement_model.dart # DTO pengumuman
│       │   └── repositories/
│       │       └── announcement_repository_impl.dart # Implementasi konkret pengumuman
│       └── presentation/
│           ├── providers/
│           │   └── announcement_providers.dart # Riverpod DI & State Provider
│           └── pages/
│               ├── home_page.dart          # Dashboard & ringkasan pengumuman
│               └── announcement_page.dart  # Detail pengumuman
├── messaging/
│   └── push_service.dart                   # FCM push service & handler isolate background
├── routes.dart                             # GoRouter terpusat & AppRoutes
└── main.dart                               # Entry-point bootstrap aplikasi
```

---

## 2. Pemetaan File Lama ke Tujuan Baru (Pindah / Pecah / Hapus)

| File Lama | Aksi | Tujuan Baru | Alasan Teknis |
|---|:---:|---|---|
| `lib/data/auth_repository.dart` | **Dipecah** | 1. `features/auth/domain/entities/auth_session.dart`<br>2. `features/auth/domain/repositories/auth_repository.dart`<br>3. `features/auth/data/repositories/auth_repository_impl.dart` | Di file lama, entity bisnis (`AuthSession`), interface kontrak, dan simulasi implementasi login berada dalam satu file. Pemecahan ini mengisolasi domain dari data. |
| `lib/data/token_store.dart` | **Dipindah** | `features/auth/data/datasources/token_store.dart` | `TokenStore` adalah local data source penyimpan token di level sistem operasi, berada di bawah data layer fitur auth. |
| `lib/data/api_client.dart` | **Dipindah** | `core/providers.dart` / `lib/data/api_client.dart` | Instance Dio adalah modul infrastruktur jaringan bersama yang disuntikkan secara global melalui Riverpod. |
| `lib/data/api_errors.dart` | **Dihapus / Diganti** | `core/failures.dart` | Menghilangkan kebocoran `DioException` ke widget; digantikan pemetaan hierarki `Failure` domain. |
| `lib/providers/auth_provider.dart` | **Dipindah** | `features/auth/presentation/providers/auth_providers.dart` | Memisahkan DI repository, use case, dan `AuthNotifier` ke presentation fitur auth. |
| `lib/pages/login_page.dart` | **Direfaktor** | `features/auth/presentation/pages/login_page.dart` | Menghapus import `dio` dan penanganan `DioException`. UI hanya menangkap error ramah pengguna. |
| `lib/pages/home_page.dart` | **Direfaktor** | `features/announcements/presentation/pages/home_page.dart` | Memindahkan logika manipulasi string token manual ke fungsi murni `core/format.dart`. |
| `lib/pages/announcement_page.dart` | **Direfaktor** | `features/announcements/presentation/pages/announcement_page.dart` | Mengubah widget statis menjadi pembaca state asinkron dari domain repository. |
| `lib/messaging/push_service.dart` | **Tetap** | `lib/messaging/push_service.dart` | Handler isolate background wajib top-level `@pragma('vm:entry-point')` sehingga dipertahankan pada modul messaging. |
| `lib/routes.dart` | **Tetap** | `lib/routes.dart` | Sentralisasi konfigurasi rute GoRouter dan pemetaan deep link. |

---

## 3. Analisis Over-Engineering vs Kapan Use Case Dibutuhkan

### A. Bagian yang Over-Engineering (Bila Diterapkan ke CRUD Sederhana):
* **Use Case Pass-Through (Satu Baris):**  
  Membuat kelas use case terpisah untuk aksi CRUD pembacaan langsung tanpa transformasi data (misal: `GetAnnouncementDetail(id)` atau `LogoutUseCase()` yang hanya memanggil `return repo.logout()`).  
  * **Biaya:** Menambah kompleksitas struktur berupa pembuatan berkas baru, kelas baru, konstruktor, dan provider baru tanpa memberikan nilai tambah logika bisnis. Pada tim kecil, hal ini menimbulkan beban pemeliharaan (*maintenance overhead*).

### B. Kapan Use Case Benar-benar Dibutuhkan:
1. **Aturan Validasi Bisnis Eksplisit:**  
   Pada `LoginUseCase`, format email domain institusi `@kampus.ac.id` dan panjang kata sandi minimal 6 karakter divalidasi sebelum data ditembakkan ke jaringan.
2. **Orkestrasi Multi-Repository / Data Source:**  
   Ketika satu aksi memerlukan koordinasi lebih dari satu sumber data (misal: login sukses -> simpan token ke secure storage -> refresh profil mahasiswa -> kirim device token FCM).
3. **Penerapan Aturan Bisnis & Transformasi Data:**  
   Pengurutan pengumuman berdasarkan tanggal rilis terbaru atau pemfilteran pengumuman darurat berdasarkan role akun mahasiswa.

---

## 4. Wiring Dependency Injection (Riverpod) & Penjelasan Trade-off

### A. Wiring Fitur Auth (`features/auth/presentation/providers/auth_providers.dart`)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';

// 1. Data Layer: Data Source & Repository Implementation
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl());

// 2. Domain Layer: Use Case menerima interface abstraksi, bukan konkret
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

// 3. Presentation Layer: State Notifier untuk UI
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref.watch(tokenStoreProvider).readAccess();
    return token != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(loginUseCaseProvider).call(email: email, password: password);
      if (result.failure != null) throw Exception(result.failure!.message);
      final session = result.session!;
      await ref.read(tokenStoreProvider).save(access: session.access, refresh: session.refresh);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(tokenStoreProvider).clear();
    ref.invalidateSelf();
  }
}
```

### B. Trade-off Setiap Keputusan Arsitektur:
1. **Feature-First vs Layer-First:**  
   *Trade-off:* Menambah jumlah subfolder di awal pengerjaan, namun memberikan isolasi modular yang kuat sehingga satu fitur dapat dikembangkan, diuji, atau dihapus tanpa mengganggu fitur lain.
2. **Dart Record `({T data, Failure? failure})` vs Package Either (`fpdart`):**  
   *Trade-off:* Memanfaatkan fitur native Dart 3 Record tanpa menambah dependensi library pihak ketiga, menjaga project tetap ringan (*zero dependency overhead*).
3. **Riverpod sebagai DI Container:**  
   *Trade-off:* Mengeliminasi kebutuhan package DI terpisah (seperti `get_it`/`injectable`), menyatukan manajemen state dan penyuntikan dependensi dalam satu ekosistem reaktif.
