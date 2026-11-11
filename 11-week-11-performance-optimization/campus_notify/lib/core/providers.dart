import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../data/api_client.dart';
import '../data/token_store.dart';
import '../data/auth_repository.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final store = TokenStore();
  final auth = AuthRepository();
  return buildApiClient(store, auth);
});
