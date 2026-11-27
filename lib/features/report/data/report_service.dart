import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/student_option.dart';

/// Nama penandatangan tetap sesuai project brief.
abstract final class ReportSignatures {
  static const String directorName = 'Ustadzah Evi Fitriana Hanifa';
  static const String directorTitle = "Direktur Rumah Qur'an Salima";
}

/// Membuat dokumen PDF rapor individu & laporan gabungan.
///
/// Data yang masuk ke service ini sudah difilter RLS Supabase, sehingga PDF
/// tidak pernah memuat data di luar hak akses pengguna.
class ReportService {
  static final PdfColor _primary = PdfColor.fromHex('#1B5E20');
  static final PdfColor _primarySoft = PdfColor.fromHex('#E8F1E8');
  static final PdfColor _border = PdfColor.fromHex('#B7C4B7');

  Future<Uint8List> buildStudentReport({
    required StudentOption student,
    required List<Assessment> assessments,
  }) async {
    final document = pw.Document(
      title: 'Rapor ${student.fullName}',
      author: "Rumah Qur'an Salima",
    );

    final sorted = [...assessments]
      ..sort((a, b) => a.assessmentDate.compareTo(b.assessmentDate));
    final evaluators = <String>{
      for (final assessment in assessments)
        if (assessment.evaluatorName.trim().isNotEmpty)
          assessment.evaluatorName,
    };

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        footer: _footer,
        build: (context) => [
          _header(
            title: 'RAPOR PERKEMBANGAN MAHASANTRI',
            subtitle: student.branchName,
          ),
          pw.SizedBox(height: 14),
          _studentInfo(student),
          pw.SizedBox(height: 16),
          _sectionTitle('Ringkasan'),
          pw.SizedBox(height: 6),
          _summaryTable(
            total: assessments.length,
            average: _averageScore(assessments),
            latestPredicate: sorted.isEmpty ? null : sorted.last.predicate,
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Rincian Penilaian'),
          pw.SizedBox(height: 6),
          if (assessments.isEmpty)
            pw.Text(
              'Belum ada penilaian pada periode ini.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            _assessmentTable(sorted),
          pw.SizedBox(height: 26),
          _signatureBlock(evaluators),
          pw.SizedBox(height: 10),
          pw.Text(
            'Dokumen ini dihasilkan otomatis oleh aplikasi Rumah Qur\'an '
            'Salima pada ${AppFormatters.longDate(DateTime.now())}.',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildCombinedReport({
    required String scopeLabel,
    required List<StudentOption> students,
    required List<Assessment> assessments,
  }) async {
    final document = pw.Document(
      title: 'Laporan Gabungan $scopeLabel',
      author: "Rumah Qur'an Salima",
    );

    final byStudent = <String, List<Assessment>>{};
    for (final assessment in assessments) {
      byStudent.putIfAbsent(assessment.studentId, () => []).add(assessment);
    }

    final rows = <_CombinedRow>[
      for (final student in students)
        _CombinedRow(
          student: student,
          assessments: byStudent[student.id] ?? const [],
        ),
    ]..sort((a, b) => a.student.fullName.compareTo(b.student.fullName));

    final reportedRows = rows.where((row) => row.assessments.isNotEmpty);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        footer: _footer,
        build: (context) => [
          _header(title: 'LAPORAN GABUNGAN PENILAIAN', subtitle: scopeLabel),
          pw.SizedBox(height: 14),
          pw.Text(
            'Total ${assessments.length} penilaian dari '
            '${reportedRows.length} mahasantri.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          if (rows.isEmpty)
            pw.Text(
              'Belum ada mahasantri pada cakupan ini.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            _combinedTable(rows),
          pw.SizedBox(height: 26),
          _signatureBlock(const {}),
          pw.SizedBox(height: 10),
          pw.Text(
            'Dokumen ini dihasilkan otomatis oleh aplikasi Rumah Qur\'an '
            'Salima pada ${AppFormatters.longDate(DateTime.now())}.',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header({required String title, required String subtitle}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "RUMAH QUR'AN SALIMA",
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  title,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _sanitize(subtitle),
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            AppFormatters.shortDate(DateTime.now()),
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _studentInfo(StudentOption student) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          _infoRow('Nama', student.fullName),
          pw.SizedBox(height: 4),
          _infoRow('NIS', student.nis ?? '-'),
          pw.SizedBox(height: 4),
          _infoRow('Cabang', student.branchName),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 70,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            _sanitize(value),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: _primary,
      ),
    );
  }

  pw.Widget _summaryTable({
    required int total,
    required double? average,
    required Predicate? latestPredicate,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primarySoft),
          children: [
            _cell('Jumlah penilaian', isHeader: true),
            _cell('Rata-rata nilai', isHeader: true),
            _cell('Predikat terakhir', isHeader: true),
          ],
        ),
        pw.TableRow(
          children: [
            _cell('$total'),
            _cell(AppFormatters.score(average)),
            _cell(latestPredicate?.label ?? '-'),
          ],
        ),
      ],
    );
  }

  pw.Widget _assessmentTable(List<Assessment> assessments) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(0.9),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(0.7),
        5: pw.FlexColumnWidth(1.7),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primarySoft),
          children: [
            _cell('Tanggal', isHeader: true),
            _cell('Kategori', isHeader: true),
            _cell('Juz', isHeader: true),
            _cell('Predikat', isHeader: true),
            _cell('Nilai', isHeader: true),
            _cell('Penilai / Catatan', isHeader: true),
          ],
        ),
        for (final assessment in assessments)
          pw.TableRow(
            children: [
              _cell(AppFormatters.shortDate(assessment.assessmentDate)),
              _cell(assessment.category.label),
              _cell(assessment.juzLabel),
              _cell(assessment.predicate?.label ?? '-'),
              _cell(AppFormatters.score(assessment.numericScore)),
              _cell(
                assessment.notes == null || assessment.notes!.isEmpty
                    ? assessment.evaluatorName
                    : '${assessment.evaluatorName} — ${assessment.notes}',
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _combinedTable(List<_CombinedRow> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.4),
        1: pw.FlexColumnWidth(2.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(0.9),
        4: pw.FlexColumnWidth(0.9),
        5: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primarySoft),
          children: [
            _cell('No', isHeader: true),
            _cell('Nama', isHeader: true),
            _cell('NIS', isHeader: true),
            _cell('Jumlah', isHeader: true),
            _cell('Rata-rata', isHeader: true),
            _cell('Predikat terakhir', isHeader: true),
          ],
        ),
        for (var index = 0; index < rows.length; index++)
          pw.TableRow(
            children: [
              _cell('${index + 1}'),
              _cell(rows[index].student.fullName),
              _cell(rows[index].student.nis ?? '-'),
              _cell('${rows[index].assessments.length}'),
              _cell(AppFormatters.score(rows[index].average)),
              _cell(rows[index].latestPredicate?.label ?? '-'),
            ],
          ),
      ],
    );
  }

  pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        _sanitize(text),
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? _primary : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _signatureBlock(Set<String> evaluators) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _signatureColumn(
            role: 'Musyrifah Penilai',
            name: evaluators.isEmpty ? '-' : evaluators.join(', '),
          ),
        ),
        pw.SizedBox(width: 24),
        pw.Expanded(
          child: _signatureColumn(
            role: ReportSignatures.directorTitle,
            name: ReportSignatures.directorName,
          ),
        ),
      ],
    );
  }

  pw.Widget _signatureColumn({required String role, required String name}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(role, style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 40),
        pw.Container(
          width: 190,
          padding: const pw.EdgeInsets.only(bottom: 2),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.7),
            ),
          ),
          child: pw.Text(
            _sanitize(name),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  /// Font bawaan PDF (Helvetica) hanya mendukung Latin-1. Ganti karakter
  /// tipografi umum agar tidak hilang dari dokumen.
  String _sanitize(String value) {
    return value
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201c', '"')
        .replaceAll('\u201d', '"')
        .replaceAll('\u2022', '-')
        .replaceAll('\u00a0', ' ');
  }

  double? _averageScore(List<Assessment> assessments) {
    final scores = assessments
        .map((assessment) => assessment.numericScore)
        .whereType<double>()
        .toList();
    if (scores.isEmpty) {
      return null;
    }
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}

class _CombinedRow {
  _CombinedRow({required this.student, required this.assessments});

  final StudentOption student;
  final List<Assessment> assessments;

  double? get average {
    final scores = assessments
        .map((assessment) => assessment.numericScore)
        .whereType<double>()
        .toList();
    if (scores.isEmpty) {
      return null;
    }
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  Predicate? get latestPredicate {
    if (assessments.isEmpty) {
      return null;
    }
    final sorted = [...assessments]
      ..sort((a, b) => a.assessmentDate.compareTo(b.assessmentDate));
    return sorted.last.predicate;
  }
}
