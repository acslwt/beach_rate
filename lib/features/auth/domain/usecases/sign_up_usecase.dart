import '../entities/user_profile.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<UserProfile> call(String email, String password) =>
      _repository.createUserWithEmailAndPassword(email, password);
}
