import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@') || password.length < 6) {
      return (
        session: null,
        failure: const AuthFailure('Email tidak valid atau kata sandi kurang dari 6 karakter'),
      );
    }
    return _repository.login(email: email, password: password);
  }
}
