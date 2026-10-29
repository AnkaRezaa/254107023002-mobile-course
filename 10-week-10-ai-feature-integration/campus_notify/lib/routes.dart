abstract class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const announcement = '/pengumuman/:id';
  static const chat = '/chat';

  static String announcementDetail(String id) => '/pengumuman/$id';
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'] as String? ?? AppRoutes.home;
  return route.startsWith('/') ? route : '/$route';
}
