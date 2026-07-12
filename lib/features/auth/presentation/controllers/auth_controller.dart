import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/failures/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

class AuthController extends ChangeNotifier {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  StreamSubscription<UserProfile?>? _authSub;

  bool _loggedIn = false;
  bool _isLoading = false;
  String? _error;
  UserProfile? _profile;

  AuthController({
    required AuthRepository repository,
    required this._signIn,
    required this._signUp,
    required this._signInWithGoogle,
    required this._signOut,
  }) {
    _authSub = repository.authStateChanges.listen((profile) {
      _profile = profile;
      _loggedIn = profile != null;
      notifyListeners();
    });
  }

  bool get loggedIn => _loggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserProfile? get profile => _profile;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) =>
      _run(() => _signIn(email, password));

  Future<void> signUpWithEmailAndPassword(String email, String password) =>
      _run(() => _signUp(email, password));

  Future<void> signInWithGoogle() => _run(() => _signInWithGoogle());

  Future<void> logout() => _runVoid(_signOut.call);

  Future<void> _run(Future<UserProfile> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on UserCancelledException {
      // user cancelled Google sign-in — no error
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _runVoid(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
