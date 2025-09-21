import 'package:cnn/features/Auth/repository/auth_repo_updated.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController {
  final AuthRepo _authRepo;

  AuthController(this._authRepo);

  Future<String?> signUp(
    String email,
    String password,
    String confirmPassword,
    String name,
    String phone,
  ) async {
    return await _authRepo.signUp(
      email,
      password,
      confirmPassword,
      name,
      phone,
    );
  }

  Future<String?> signIn(String email, String password) async {
    return await _authRepo.signIn(email, password);
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final repo = ref.watch(authRepo);
  return AuthController(repo);
});
