import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!email.contains('@') || password.length < 6) {
        return (
          session: null,
          failure: const AuthFailure('Email atau kata sandi tidak valid'),
        );
      }
      final model = AuthSessionModel(
        access: 'mock-access-for-$email',
        refresh: 'mock-refresh-for-$email',
      );
      return (session: model.toEntity(), failure: null);
    } catch (e) {
      return (
        session: null,
        failure: NetworkFailure('Gagal melakukan login: $e'),
      );
    }
  }

  @override
  Future<({String? access, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (refreshToken.isEmpty) {
        return (
          access: null,
          failure: const AuthFailure('Refresh token kosong'),
        );
      }
      return (
        access: 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}',
        failure: null,
      );
    } catch (e) {
      return (
        access: null,
        failure: NetworkFailure('Gagal memperbarui token: $e'),
      );
    }
  }
}
