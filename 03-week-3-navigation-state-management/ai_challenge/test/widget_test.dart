// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_challenge/main.dart';

void main() {
  test(
    'notifier menghasilkan tiga statistik ketika request berhasil',
    () async {
      // Override fetcher membuat test cepat dan tidak bergantung pada random.
      final container = ProviderContainer(
        overrides: [
          statisticsProvider.overrideWith(() {
            final notifier = StatisticsNotifier();
            notifier.fetcher =
                () async => const [
                  Statistic(label: 'A', value: '1'),
                  Statistic(label: 'B', value: '2'),
                  Statistic(label: 'C', value: '3'),
                ];
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(statisticsProvider.future);

      expect(result, hasLength(3));
      expect(result.first.label, 'A');
    },
  );

  test('notifier meneruskan error ketika request gagal', () async {
    // Fetcher gagal secara sengaja untuk memverifikasi state error notifier.
    final container = ProviderContainer(
      overrides: [
        statisticsProvider.overrideWith(() {
          final notifier = StatisticsNotifier();
          notifier.fetcher = () async => throw Exception('Gagal');
          return notifier;
        }),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(statisticsProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}
