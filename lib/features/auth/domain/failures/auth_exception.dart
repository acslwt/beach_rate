class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class UserCancelledException extends AuthException {
  const UserCancelledException() : super('');
}
