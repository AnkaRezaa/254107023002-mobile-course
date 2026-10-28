String formatDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();
  return '$day/$month/$year';
}

String maskToken(String? token) {
  if (token == null || token.isEmpty) return 'Mengambil token...';
  if (token.length <= 12) return token;
  return '${token.substring(0, 12)}...';
}

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route'] as String? ?? '/';
  return route.startsWith('/') ? route : '/$route';
}
