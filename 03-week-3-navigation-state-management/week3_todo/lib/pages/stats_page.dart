// lib/pages/stats_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final completed = todos.where((todo) => todo.done).length;
    final unfinished = todos.length - completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            label: 'Total tugas',
            value: todos.length,
          ),
          _StatCard(
            label: 'Tugas selesai',
            value: completed,
          ),
          _StatCard(
            label: 'Belum selesai',
            value: unfinished,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}