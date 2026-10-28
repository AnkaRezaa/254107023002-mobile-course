import '../entities/announcement.dart';

class SearchAnnouncements {
  const SearchAnnouncements();

  List<Announcement> call({
    required List<Announcement> items,
    required String query,
  }) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return items;
    }
    return items.where((item) {
      final matchesTitle = item.title.toLowerCase().contains(trimmedQuery);
      final matchesBody = item.body.toLowerCase().contains(trimmedQuery);
      return matchesTitle || matchesBody;
    }).toList();
  }
}
