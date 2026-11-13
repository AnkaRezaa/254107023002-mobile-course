import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/announcements/presentation/pages/announcement_page.dart';

void main() {
  group('AnnouncementEmptyView Widget Tests', () {
    testWidgets('menampilkan pesan query tidak ditemukan dan icon search_off', (
      tester,
    ) async {
      const testQuery = 'robotika';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AnnouncementEmptyView(query: testQuery)),
        ),
      );

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('Pengumuman tidak ditemukan'), findsOneWidget);
      expect(
        find.textContaining(
          'Tidak ada pengumuman yang cocok dengan "$testQuery"',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'menampilkan pesan default saat belum ada pengumuman sama sekali',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: AnnouncementEmptyView(query: '')),
          ),
        );

        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('Belum ada pengumuman.'), findsOneWidget);
      },
    );
  });
}
