import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;
  const SignInUseCase(this._repository);

  Future<UserProfile> call(String email, String password) =>
      _repository.signInWithEmailAndPassword(email, password);
}
