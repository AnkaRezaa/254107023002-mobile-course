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
    return items
        .where((item) => item.title.toLowerCase().contains(trimmedQuery))
        .toList();
  }
}
