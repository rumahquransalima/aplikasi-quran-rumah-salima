/// Pemformat tanggal & angka berbahasa Indonesia tanpa bergantung pada data
/// locale `intl` tambahan, sehingga tetap aman dipakai di widget test.
abstract final class AppFormatters {
  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _longMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String shortDate(DateTime date) =>
      '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';

  static String longDate(DateTime date) =>
      '${date.day} ${_longMonths[date.month - 1]} ${date.year}';

  static String monthLabel(DateTime date) =>
      '${_shortMonths[date.month - 1]} ${date.year}';

  /// Format ISO (yyyy-MM-dd) yang dipakai kolom `date` Supabase.
  static String isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String time(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String shortDateTime(DateTime date) =>
      '${shortDate(date)}, ${time(date)}';

  static String score(double? value) {
    if (value == null) {
      return '-';
    }
    final rounded = value.toStringAsFixed(2);
    return rounded.endsWith('.00')
        ? rounded.substring(0, rounded.length - 3)
        : rounded;
  }
}
