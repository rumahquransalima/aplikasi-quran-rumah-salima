/// Validator form yang dipakai lintas fitur.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phonePattern = RegExp(r'^[0-9+()\-\s]{8,30}$');

  static String? required(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, field: 'Email');
    if (requiredError != null) {
      return requiredError;
    }

    final email = value!.trim();
    if (!_emailPattern.hasMatch(email)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, field: 'Kata sandi');
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.length < 6) {
      return 'Kata sandi minimal 6 karakter.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = required(value, field: 'Konfirmasi kata sandi');
    if (requiredError != null) {
      return requiredError;
    }

    if (value != password) {
      return 'Konfirmasi kata sandi tidak sama.';
    }
    return null;
  }

  /// Nomor telepon opsional. Jika diisi, hanya boleh berisi angka dan
  /// pemisah umum (spasi, +, -, tanda kurung).
  static String? optionalPhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return null;
    }

    if (!_phonePattern.hasMatch(phone)) {
      return 'Format nomor telepon tidak valid.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final requiredError = required(value, field: 'Nama lengkap');
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 3) {
      return 'Nama lengkap minimal 3 karakter.';
    }
    return null;
  }
}
