// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:praktikum/data/paged_posts.dart';
import 'package:praktikum/main.dart';

// Notifier palsu mencegah smoke test melakukan request HTTP sungguhan.
class FakePagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() => const PagedPostsState();
}

void main() {
  testWidgets('halaman pagination tampil di dalam ProviderScope',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pagedPostsProvider.overrideWith(FakePagedPostsNotifier.new),
        ],
        child: MyApp(),
      ),
    );

    // Frame pertama sudah harus menampilkan judul halaman pagination.
    await tester.pump();
    expect(find.text('Posts Paged'), findsOneWidget);
  });
}
