import 'package:flutter_test/flutter_test.dart';
import 'package:rumah_quran_salima/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('menolak email kosong', () {
      expect(Validators.email(null), 'Email wajib diisi.');
      expect(Validators.email('   '), 'Email wajib diisi.');
    });

    test('menolak format email tidak valid', () {
      expect(Validators.email('bukan-email'), 'Format email tidak valid.');
      expect(Validators.email('nama@'), 'Format email tidak valid.');
    });

    test('menerima email valid', () {
      expect(Validators.email('santri@contoh.id'), isNull);
      expect(Validators.email('  santri@contoh.id  '), isNull);
    });
  });

  group('Validators.password', () {
    test('menolak kata sandi kosong', () {
      expect(Validators.password(null), 'Kata sandi wajib diisi.');
    });

    test('menolak kata sandi kurang dari 6 karakter', () {
      expect(Validators.password('12345'), 'Kata sandi minimal 6 karakter.');
    });

    test('menerima kata sandi minimal 6 karakter', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('menolak konfirmasi kosong', () {
      expect(
        Validators.confirmPassword(null, '123456'),
        'Konfirmasi kata sandi wajib diisi.',
      );
    });

    test('menolak konfirmasi yang berbeda', () {
      expect(
        Validators.confirmPassword('123457', '123456'),
        'Konfirmasi kata sandi tidak sama.',
      );
    });

    test('menerima konfirmasi yang sama', () {
      expect(Validators.confirmPassword('123456', '123456'), isNull);
    });
  });

  group('Validators.optionalPhone', () {
    test('mengizinkan nomor telepon kosong', () {
      expect(Validators.optionalPhone(null), isNull);
      expect(Validators.optionalPhone(''), isNull);
    });

    test('menolak format nomor telepon tidak valid', () {
      expect(
        Validators.optionalPhone('abc'),
        'Format nomor telepon tidak valid.',
      );
    });

    test('menerima nomor telepon umum', () {
      expect(Validators.optionalPhone('0812-3456-7890'), isNull);
      expect(Validators.optionalPhone('+62 812 3456 7890'), isNull);
    });
  });

  group('Validators.fullName', () {
    test('menolak nama kosong', () {
      expect(Validators.fullName(''), 'Nama lengkap wajib diisi.');
    });

    test('menolak nama terlalu pendek', () {
      expect(Validators.fullName('Al'), 'Nama lengkap minimal 3 karakter.');
    });

    test('menerima nama valid', () {
      expect(Validators.fullName('Aisyah Salima'), isNull);
    });
  });
}
