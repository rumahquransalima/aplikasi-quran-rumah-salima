import 'package:supabase_flutter/supabase_flutter.dart';

/// Akses tunggal ke Supabase client.
///
/// Semua transaksi data WAJIB melewati client ini sehingga:
/// - sesi auth otomatis disertakan pada setiap request;
/// - RLS di Supabase dapat mengevaluasi `auth.uid()` dan role pengguna;
/// - tidak ada database lokal yang menjadi sumber data utama.
abstract final class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static Session? get currentSession => auth.currentSession;

  static User? get currentUser => auth.currentUser;

  static String? get currentUserId => auth.currentUser?.id;

  static bool get isLoggedIn => auth.currentSession != null;

  /// Stream perubahan status login; dipakai AuthBloc/AuthGate pada tahap 1.
  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  static Future<void> signOut() async {
    await auth.signOut();
  }
}
