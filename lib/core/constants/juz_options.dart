/// Pilihan Juz yang valid sesuai constraint database `^(10|[1-9])[ab]$`.
abstract final class JuzOptions {
  static const List<String> values = [
    '1a',
    '1b',
    '2a',
    '2b',
    '3a',
    '3b',
    '4a',
    '4b',
    '5a',
    '5b',
    '6a',
    '6b',
    '7a',
    '7b',
    '8a',
    '8b',
    '9a',
    '9b',
    '10a',
    '10b',
  ];

  static bool isValid(String value) => values.contains(value);
}
