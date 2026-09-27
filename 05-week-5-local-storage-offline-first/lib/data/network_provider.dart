import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';


// Repository Providers
final noteRepositoryProvider = Provider((ref) => NoteRepository());
final postRepositoryProvider = Provider((ref) => PostRepository());

// Provider untuk Force Offline Switch
final forceOfflineProvider = StateProvider<bool>((ref) => false);

