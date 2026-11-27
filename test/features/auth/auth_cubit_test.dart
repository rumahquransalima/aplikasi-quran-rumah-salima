import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/features/auth/data/auth_repository.dart';
import 'package:rumah_quran_salima/features/auth/domain/app_user.dart';
import 'package:rumah_quran_salima/features/auth/domain/user_role.dart';
import 'package:rumah_quran_salima/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:rumah_quran_salima/features/auth/presentation/cubit/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('AuthCubit', () {
    test('menghasilkan AuthUnauthenticated saat tidak ada sesi', () async {
      final repository = _FakeAuthRepository();
      final cubit = AuthCubit(repository);

      await cubit.initialize();

      expect(cubit.state, isA<AuthUnauthenticated>());

      await cubit.close();
      await repository.dispose();
    });

    test('memuat profil saat event signedIn diterima', () async {
      final user = _user();
      final repository = _FakeAuthRepository(user: user);
      final cubit = AuthCubit(repository);

      repository.emit(
        const supabase.AuthState(supabase.AuthChangeEvent.signedIn, null),
      );
      await pumpEventQueue();

      expect(cubit.state, isA<AuthAuthenticated>());
      expect((cubit.state as AuthAuthenticated).user, user);

      await cubit.close();
      await repository.dispose();
    });

    test('menghasilkan AuthInactive untuk profil nonaktif', () async {
      final user = _user(isActive: false);
      final repository = _FakeAuthRepository(user: user);
      final cubit = AuthCubit(repository);

      repository.emit(
        const supabase.AuthState(supabase.AuthChangeEvent.signedIn, null),
      );
      await pumpEventQueue();

      expect(cubit.state, isA<AuthInactive>());
      expect((cubit.state as AuthInactive).user, user);

      await cubit.close();
      await repository.dispose();
    });

    test(
      'menghasilkan AuthPasswordRecovery saat tautan reset dibuka',
      () async {
        final repository = _FakeAuthRepository(user: _user());
        final cubit = AuthCubit(repository);

        repository.emit(
          const supabase.AuthState(
            supabase.AuthChangeEvent.passwordRecovery,
            null,
          ),
        );
        await pumpEventQueue();

        expect(cubit.state, isA<AuthPasswordRecovery>());

        await cubit.close();
        await repository.dispose();
      },
    );

    test('updatePassword mengembalikan state ke AuthAuthenticated', () async {
      final user = _user();
      final repository = _FakeAuthRepository(user: user);
      final cubit = AuthCubit(repository);

      repository.emit(
        const supabase.AuthState(
          supabase.AuthChangeEvent.passwordRecovery,
          null,
        ),
      );
      await pumpEventQueue();
      expect(cubit.state, isA<AuthPasswordRecovery>());

      await cubit.updatePassword('kata-sandi-baru');
      await pumpEventQueue();

      expect(cubit.state, isA<AuthAuthenticated>());
      expect(repository.lastUpdatedPassword, 'kata-sandi-baru');

      await cubit.close();
      await repository.dispose();
    });

    test('signOut menghasilkan AuthUnauthenticated', () async {
      final repository = _FakeAuthRepository(user: _user());
      final cubit = AuthCubit(repository);

      repository.emit(
        const supabase.AuthState(supabase.AuthChangeEvent.signedIn, null),
      );
      await pumpEventQueue();
      expect(cubit.state, isA<AuthAuthenticated>());

      await cubit.signOut();
      await pumpEventQueue();

      expect(cubit.state, isA<AuthUnauthenticated>());
      expect(repository.signedOut, isTrue);

      await cubit.close();
      await repository.dispose();
    });

    test('event signedOut menghasilkan AuthUnauthenticated', () async {
      final repository = _FakeAuthRepository(user: _user());
      final cubit = AuthCubit(repository);

      repository.emit(
        const supabase.AuthState(supabase.AuthChangeEvent.signedIn, null),
      );
      await pumpEventQueue();
      expect(cubit.state, isA<AuthAuthenticated>());

      repository.emit(
        const supabase.AuthState(supabase.AuthChangeEvent.signedOut, null),
      );
      await pumpEventQueue();

      expect(cubit.state, isA<AuthUnauthenticated>());

      await cubit.close();
      await repository.dispose();
    });
  });
}

AppUser _user({bool isActive = true}) {
  return AppUser(
    id: 'user-1',
    fullName: 'Aisyah Salima',
    email: 'aisyah@contoh.id',
    role: UserRole.mahasantri,
    isActive: isActive,
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.user});

  final AppUser? user;
  final _controller = StreamController<supabase.AuthState>.broadcast();

  bool signedOut = false;
  String? lastUpdatedPassword;
  String? lastUpdatedFullName;
  String? lastUpdatedPhone;

  @override
  Future<void> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    lastUpdatedFullName = fullName;
    lastUpdatedPhone = phone;
  }

  @override
  supabase.Session? get currentSession => null;

  @override
  String? get currentUserId => user?.id;

  @override
  Stream<supabase.AuthState> get authStateChanges => _controller.stream;

  @override
  Future<AppUser?> fetchCurrentUser() async => user;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    return const SignUpResult(requiresEmailConfirmation: false);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String password) async {
    lastUpdatedPassword = password;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  void emit(supabase.AuthState event) {
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}
