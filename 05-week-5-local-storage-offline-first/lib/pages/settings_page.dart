import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

final lastOpenedProvider = FutureProvider<String?>((ref) {
  return ref.watch(prefsRepositoryProvider).getLastOpened();
});

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(prefsRepositoryProvider).getDarkMode();
  }

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastOpened = ref.watch(lastOpenedProvider);
    final darkMode = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          darkMode.when(
            data: (enabled) => SwitchListTile(
              title: const Text('Mode gelap'),
              value: enabled,
              onChanged: (_) {
                ref.read(darkModeProvider.notifier).toggle();
              },
            ),
            loading: () => const ListTile(
              title: Text('Memuat preferensi tema...'),
            ),
            error: (error, stack) => ListTile(
              title: Text('Gagal membaca tema: $error'),
            ),
          ),
          lastOpened.when(
            data: (value) => ListTile(
              title: const Text('Terakhir dibuka'),
              subtitle: Text(value ?? 'Belum ada data'),
            ),
            loading: () => const ListTile(
              title: Text('Memuat waktu terakhir dibuka...'),
            ),
            error: (error, stack) => ListTile(
              title: Text('Gagal membaca waktu: $error'),
            ),
          ),
        ],
      ),
    );
  }
}