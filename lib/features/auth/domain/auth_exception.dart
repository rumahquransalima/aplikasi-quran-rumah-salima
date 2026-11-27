/// Error autentikasi yang pesannya sudah siap ditampilkan ke pengguna.
class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
