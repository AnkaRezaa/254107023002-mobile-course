import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';


// Repository Providers
final noteRepositoryProvider = Provider((ref) => NoteRepository());
final postRepositoryProvider = Provider((ref) => PostRepository());

// Provider untuk Force Offline Switch
final forceOfflineProvider = StateProvider<bool>((ref) => false);

// Provider Sinkronisasi Catatan Kotor (Dirty)
Future<int> syncNotes(
  NoteRepository repo, {
  bool forceOffline = false,
}) async {
  if (forceOffline) {
    throw Exception('Gagal sinkronisasi: Mode Force Offline aktif');
  }

  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}