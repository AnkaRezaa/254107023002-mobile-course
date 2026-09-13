import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model satu baris statistik yang ditampilkan pada halaman.
class Statistic {
  const Statistic({required this.label, required this.value});

  final String label;
  final String value;
}

/// Fungsi pengambil data yang dapat diganti pada unit test.
typedef StatisticsFetcher = Future<List<Statistic>> Function();

/// AsyncNotifier mengatur state loading, success, dan error statistik.
class StatisticsNotifier extends AsyncNotifier<List<Statistic>> {
  /// Sumber data default mensimulasikan request API selama dua detik.
  StatisticsFetcher fetcher = _fetchStatistics;

  @override
  Future<List<Statistic>> build() => fetcher();

  /// Menjalankan ulang request ketika tombol Retry ditekan.
  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(fetcher);
  }
}

/// Satu provider yang dipakai oleh halaman dan test notifier.
final statisticsProvider =
    AsyncNotifierProvider<StatisticsNotifier, List<Statistic>>(
      StatisticsNotifier.new,
    );

/// Simulasi request: delay dua detik dan peluang gagal sebesar 30 persen.
Future<List<Statistic>> _fetchStatistics() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  if (Random().nextDouble() < 0.3) {
    throw Exception('Data statistik gagal dimuat.');
  }
  return const [
    Statistic(label: 'Pengguna aktif', value: '1.248'),
    Statistic(label: 'Pesanan selesai', value: '856'),
    Statistic(label: 'Pendapatan bulan ini', value: 'Rp 24,5 jt'),
  ];
}

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

/// Root aplikasi yang menyediakan tema dan halaman statistik.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Statistics Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const StatsPage(),
    );
  }
}

/// ConsumerWidget membaca provider dan membangun UI sesuai state asynchronous.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsState = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: statisticsState.when(
        // Spinner ditampilkan selama data sedang diambil.
        loading: () => const Center(child: CircularProgressIndicator()),
        // Pesan error dan Retry ditampilkan ketika request gagal.
        error:
            (error, _) => _ErrorView(
              message: error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.read(statisticsProvider.notifier).retry(),
            ),
        // Tiga data sukses ditampilkan sebagai item-item ListView.
        data:
            (statistics) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: statistics.length,
              itemBuilder: (context, index) {
                final statistic = statistics[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: Text(statistic.label),
                    trailing: Text(
                      statistic.value,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

/// Widget kecil untuk menampilkan error secara terpusat.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
