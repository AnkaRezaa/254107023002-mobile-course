import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'messaging/push_service.dart';
import 'providers/auth_provider.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/announcement_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  registerBackgroundHandler();
  await initLocalNotifications();
  await requestNotificationPermission();

  runApp(
    const ProviderScope(
      child: CampusNotifyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(false);
  ref.listen(authStateProvider, (_, next) {
    authNotifier.value = next.value ?? false;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = ref.read(authStateProvider).value ?? false;
      final goingLogin = state.matchedLocation == '/login';

      if (!loggedIn && !goingLogin) return '/login';
      if (loggedIn && goingLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomePage(),
      ),
      GoRoute(
        path: '/pengumuman/:id',
        builder: (_, s) => AnnouncementPage(
          id: s.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
});

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

Future<void> _setupFCM() async {
  // Dengarkan saat notifikasi diklik (Foreground banner & Background)
  listenForeground((route) {
    ref.read(routerProvider).push(route);
  });

  
  // Periksa apakah aplikasi dibuka dari kondisi mati (Terminated)
  await handleTerminated((route) {
    ref.read(routerProvider).push(route);
  });
  // Ambil token FCM dan simpan
 await initFcmToken(
  onToken: (token) async {
    debugPrint('FCM TOKEN DITERIMA: $token');
    if (mounted) {
      ref.read(fcmTokenProvider.notifier).setToken(token);
    }
  },
);

}

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Campus Notify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
