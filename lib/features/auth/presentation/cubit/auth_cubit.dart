import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../data/auth_repository.dart';
import '../../domain/auth_exception.dart';
import 'auth_state.dart';

/// Menjaga status sesi login dan memuat profil pengguna dari Supabase.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial()) {
    _authSubscription = _repository.authStateChanges.listen(
      _onAuthStateChanged,
      onError: _onAuthStreamError,
    );
  }

  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSubscription;
  String? _loadedUserId;
  bool _isLoadingProfile = false;
  bool _passwordRecoveryActive = false;

  Future<void> initialize() async {
    if (_repository.currentUserId == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    await _loadProfile(force: true);
  }

  Future<void> signIn({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) {
    return _repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _repository.sendPasswordReset(email);
  }

  Future<void> updatePassword(String password) async {
    await _repository.updatePassword(password);
    _passwordRecoveryActive = false;
    await _loadProfile(force: true);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _loadedUserId = null;
    _passwordRecoveryActive = false;
    if (!isClosed) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    await _repository.updateProfile(fullName: fullName, phone: phone);
    await _loadProfile(force: true);
  }

  Future<void> refreshProfile() => _loadProfile(force: true);

  void _onAuthStateChanged(supabase.AuthState event) {
    switch (event.event) {
      case supabase.AuthChangeEvent.initialSession:
        if (event.session == null && _repository.currentUserId == null) {
          _loadedUserId = null;
          emit(const AuthUnauthenticated());
        } else {
          unawaited(_loadProfile());
        }
      case supabase.AuthChangeEvent.signedIn:
      case supabase.AuthChangeEvent.userUpdated:
      case supabase.AuthChangeEvent.mfaChallengeVerified:
        unawaited(_loadProfile(force: true));
      case supabase.AuthChangeEvent.signedOut:
        _loadedUserId = null;
        _passwordRecoveryActive = false;
        emit(const AuthUnauthenticated());
      case supabase.AuthChangeEvent.passwordRecovery:
        _passwordRecoveryActive = true;
        emit(const AuthPasswordRecovery());
      case supabase.AuthChangeEvent.tokenRefreshed:
      default:
        break;
    }
  }

  void _onAuthStreamError(Object error, StackTrace stackTrace) {
    if (isClosed) {
      return;
    }
    emit(
      const AuthFailure(
        'Sesi login bermasalah. Silakan masuk kembali atau periksa koneksi '
        'internet Anda.',
      ),
    );
  }

  Future<void> _loadProfile({bool force = false}) async {
    if (_isLoadingProfile) {
      return;
    }

    final userId = _repository.currentUserId;
    if (userId == null) {
      _loadedUserId = null;
      if (!isClosed) {
        emit(const AuthUnauthenticated());
      }
      return;
    }

    if (!force &&
        _loadedUserId == userId &&
        (state is AuthAuthenticated || state is AuthInactive)) {
      return;
    }

    _isLoadingProfile = true;
    // Saat refresh profil (mis. setelah edit nama), jangan tampilkan layar
    // loading global agar pengguna tidak kehilangan tab yang sedang dibuka.
    final hasLoadedUser = state is AuthAuthenticated || state is AuthInactive;
    if (!isClosed && !(force && hasLoadedUser)) {
      emit(const AuthLoading());
    }

    try {
      final user = await _repository.fetchCurrentUser();
      if (isClosed) {
        return;
      }

      if (user == null) {
        _loadedUserId = null;
        emit(const AuthUnauthenticated());
        return;
      }

      _loadedUserId = user.id;
      if (_passwordRecoveryActive) {
        return;
      }

      emit(user.isActive ? AuthAuthenticated(user) : AuthInactive(user));
    } on AuthRepositoryException catch (error) {
      if (isClosed) {
        return;
      }
      _loadedUserId = null;
      emit(AuthFailure(error.message));
    } catch (_) {
      if (isClosed) {
        return;
      }
      _loadedUserId = null;
      emit(
        const AuthFailure(
          'Profil tidak dapat dimuat. Periksa koneksi internet Anda lalu coba '
          'lagi.',
        ),
      );
    } finally {
      _isLoadingProfile = false;
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
