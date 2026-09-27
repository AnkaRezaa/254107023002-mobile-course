import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local/note.dart';
import 'network_provider.dart' as network;
import 'sync.dart' as sync;

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

final dirtyCountProvider = FutureProvider<int>((ref) {
  return ref.watch(network.noteRepositoryProvider).countDirty();
});

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    return ref.watch(network.noteRepositoryProvider).fetchNotes();
  }

  Future<void> addNote(String title, String body) async {
    final repository = ref.read(network.noteRepositoryProvider);
    await repository.addNote(title: title, body: body);
    await _reloadNotes();
  }

  Future<void> deleteNote(int id) async {
    final repository = ref.read(network.noteRepositoryProvider);
    await repository.deleteNote(id);
    await _reloadNotes();
  }

  // lib/data/notes_provider.dart
Future<void> syncNotes() async {
  final repository = ref.read(network.noteRepositoryProvider);
  final forceOffline = ref.read(network.forceOfflineProvider);

await sync.syncNotes(repository, forceOffline: forceOffline);
  await _reloadNotes();
}

  Future<void> _reloadNotes() async {
    final repository = ref.read(network.noteRepositoryProvider);
    state = AsyncData(await repository.fetchNotes());
    ref.invalidate(dirtyCountProvider);
  }
}