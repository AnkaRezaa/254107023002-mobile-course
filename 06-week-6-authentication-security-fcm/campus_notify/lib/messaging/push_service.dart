import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ============================================================================
// ⚠️ BAGIAN YANG TIDAK BOLEH MENGAKSES BuildContext (Isolate Terpisah)
// ============================================================================
/// Background message handler WAJIB berupa fungsi top-level atau static.
/// Berjalan di Background Isolate terpisah dari UI Engine utama.
/// ❌ DILARANG KERAS mengakses: BuildContext, Riverpod ref, atau memanggil Navigator/Router di sini.
/// ✅ Hanya boleh: Melakukan logging ringan, penyimpanan lokal sederhana, atau kalkulasi background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Pesan masuk: ${message.messageId}');
  debugPrint('[FCM Background] Data payload: ${message.data}');
}

class PushService {
  PushService({
    required this.dio,
    required this.onNavigate,
    this.onTokenReceived,
  });

  final Dio dio;
  final void Function(String route) onNavigate;
  final void Function(String token)? onTokenReceived;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String topicPengumuman = 'pengumuman-kampus';
  static const String channelId = 'campus_announcements';
  static const String channelName = 'Pengumuman Kampus';

  // --------------------------------------------------------------------------
  // 1. Inisialisasi & Request Permission
  // --------------------------------------------------------------------------
  Future<void> initialize() async {
    // Daftarkan background handler sebelum event handler lainnya
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Minta izin notifikasi
    await requestPermission();

    // Inisialisasi local notifications untuk Foreground Banner
    await _initLocalNotifications();

    // Setup listener untuk 3 State aplikasi
    _setupMessageHandlers();

    // Setup Token Lifecycle (Get, Refresh, & Kirim ke Backend)
    await _setupTokenLifecycle();

    // Otomatis subscribe ke topik broadcast kampus
    await subscribePengumuman();
  }

  /// Meminta izin notifikasi runtime
  Future<bool> requestPermission() async {
    // ========================================================================
    // 🔍 PERBEDAAN ANDROID 13+ vs iOS:
    // - Android < 13: Izin notifikasi otomatis AKTIF saat instalasi (install-time).
    // - Android 13+ (API 33+): Wajib izin runtime pop-up dialog.
    //   Wajib deklarasikan: <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/> di AndroidManifest.xml.
    // - iOS: Selalu wajib meminta izin runtime (alert, badge, sound).
    //   Di iOS, APNs token harus siap sebelum FCM token bisa di-generate.
    // ========================================================================
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // iOS: set true jika ingin silent trial notification
    );

    // Khusus iOS: Mengatur agar notifikasi tetap berbunyi/muncul saat foreground
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final isGranted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('[FCM] Status Izin Notifikasi: ${settings.authorizationStatus}');
    return isGranted;
  }

  // --------------------------------------------------------------------------
  // 2. Inisialisasi Local Notifications
  // --------------------------------------------------------------------------
  Future<void> _initLocalNotifications() async {
    // ========================================================================
    // 🔍 PERBEDAAN ANDROID vs iOS (Inisialisasi Plugin):
    // - Android: Butuh nama icon resource (mis. '@mipmap/ic_launcher').
    // - iOS: Menggunakan DarwinInitializationSettings dengan request izin spesifik.
    // ========================================================================
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Klik banner local notification saat Foreground -> Navigasi
        final route = response.payload;
        if (route != null && route.isNotEmpty) {
          onNavigate(route);
        }
      },
    );
  }

  // --------------------------------------------------------------------------
  // 3. Token Lifecycle: Get, onTokenRefresh, Kirim ke Backend
  // --------------------------------------------------------------------------
  Future<void> _setupTokenLifecycle() async {
    try {
      // 1. Ambil token saat ini
      final token = await _fcm.getToken();
      if (token != null) {
        final masked =
            token.length > 12 ? '${token.substring(0, 12)}...' : token;
        debugPrint('[FCM] Token Perangkat (Masked): $masked');
        onTokenReceived?.call(token);
        await sendTokenToBackend(token);
      }

      // 2. Pantau rotasi token (reinstall, clear cache, update keamanan)
      // Wajib ada agar backend tidak menyimpan token basi!
      _fcm.onTokenRefresh.listen((newToken) async {
        final masked =
            newToken.length > 12 ? '${newToken.substring(0, 12)}...' : newToken;
        debugPrint('[FCM] Token Diperbarui (Masked): $masked');
        onTokenReceived?.call(newToken);
        await sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token: $e');
    }
  }

  /// Kirim token ke backend kampus
  Future<void> sendTokenToBackend(String token) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await dio.post('/devices', data: {
        'fcm_token': token,
        'platform': platform,
      });
      debugPrint('[FCM] Token berhasil disinkronkan ke backend');
    } catch (e) {
      debugPrint('[FCM] Gagal mengirim token ke backend (Mock/Offline): $e');
    }
  }

  // --------------------------------------------------------------------------
  // 4. Message Handlers (Foreground, Background Click, Terminated)
  // --------------------------------------------------------------------------
  void _setupMessageHandlers() {
    // A. STATE 1: FOREGROUND (Aplikasi sedang aktif dibuka)
    // Sistem OS TIDAK memunculkan banner otomatis -> buat banner manual via local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM Foreground] Pesan masuk: ${message.notification?.title}');

      final notification = message.notification;
      final route = message.data['route'] ?? '/';

      if (notification != null) {
        // Android Notification Channel (Wajib untuk Android 8.0+)
        const androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Saluran resmi pengumuman darurat dan akademik',
          importance: Importance.high,
          priority: Priority.high,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
        );

        await _localNotifications.show(
          id: message.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: notificationDetails,
          payload: route, // Sisipkan rute untuk navigasi saat banner diklik
        );
      }
    });

    // B. STATE 2: BACKGROUND (Aplikasi di-minimize -> Banner sistem diklik)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM Background Click] Notifikasi diklik');
      final route = message.data['route'];
      if (route != null && route.isNotEmpty) {
        onNavigate(route);
      }
    });

    // C. STATE 3: TERMINATED (Aplikasi mati total -> Dibuka via klik notifikasi)
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM Terminated Launch] Dibuka dari notifikasi mati total');
      final route = initialMessage.data['route'];
      if (route != null && route.isNotEmpty) {
        // Tunda sekejap memastikan router sudah siap me-mount rute awal
        Future.microtask(() => onNavigate(route));
      }
    }
  }

  // --------------------------------------------------------------------------
  // 5. Topic Messaging: Subscribe / Unsubscribe
  // --------------------------------------------------------------------------
  Future<void> subscribePengumuman() async {
    await _fcm.subscribeToTopic(topicPengumuman);
    debugPrint('[FCM Topic] Berlangganan topik: $topicPengumuman');
  }

  Future<void> unsubscribePengumuman() async {
    await _fcm.unsubscribeFromTopic(topicPengumuman);
    debugPrint('[FCM Topic] Berhenti langganan topik: $topicPengumuman');
  }
}
