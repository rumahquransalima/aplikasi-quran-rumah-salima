import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../assessment/data/assessment_paging.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../assessment/data/supabase_assessment_repository.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/student_option.dart';
import '../../auth/domain/app_user.dart';
import '../data/report_service.dart';

/// Layar unduh rapor individu & laporan gabungan PDF.
///
/// Hak akses:
/// - Mahasantri hanya dapat membuat rapor miliknya sendiri.
/// - Musyrifah hanya untuk mahasantri/cabang tugasnya.
/// - Admin dapat memilih semua mahasantri dan seluruh cabang.
///
/// Daftar mahasantri sudah difilter RLS Supabase, jadi UI tidak dapat memilih
/// data di luar wewenang pengguna.
const String _allBranches = '__all_branches__';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.user, this.repository});

  final AppUser user;
  final AssessmentRepository? repository;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final AssessmentRepository _repository;
  final _reportService = ReportService();

  List<StudentOption> _students = const [];
  String? _selectedStudentId;
  String? _selectedBranchId;
  bool _isLoadingStudents = true;
  String? _loadError;
  bool _isGeneratingStudent = false;
  bool _isGeneratingCombined = false;

  bool get _isStaff => widget.user.isAdmin || widget.user.isMusyrifah;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseAssessmentRepository();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _loadError = null;
    });

    try {
      final students = await _repository.fetchStudents();
      if (!mounted) {
        return;
      }
      setState(() {
        _students = students.where((student) => student.isActive).toList();
        if (widget.user.isMahasantri) {
          for (final student in _students) {
            if (student.id == widget.user.studentId) {
              _selectedStudentId = student.id;
              break;
            }
          }
        }
      });
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        setState(() => _loadError = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
      }
    }
  }

  StudentOption? get _selectedStudent {
    for (final student in _students) {
      if (student.id == _selectedStudentId) {
        return student;
      }
    }
    return null;
  }

  Future<void> _generateStudentReport() async {
    if (_isGeneratingStudent) {
      return;
    }

    final student = _selectedStudent;
    if (student == null) {
      _showMessage('Pilih mahasantri terlebih dahulu.');
      return;
    }

    setState(() => _isGeneratingStudent = true);

    try {
      final assessments = await _repository.fetchAllAssessments(
        AssessmentQuery(studentId: student.id),
      );
      final bytes = await _reportService.buildStudentReport(
        student: student,
        assessments: assessments,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'rapor_${_slug(student.fullName)}.pdf',
      );
      if (mounted) {
        _showMessage('Rapor ${student.fullName} berhasil dibuat.');
      }
    } on AssessmentRepositoryException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Rapor PDF gagal dibuat. Periksa koneksi internet dan penyimpanan '
        'perangkat Anda.',
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingStudent = false);
      }
    }
  }

  Future<void> _generateCombinedReport() async {
    if (_isGeneratingCombined) {
      return;
    }

    setState(() => _isGeneratingCombined = true);

    try {
      BranchInfo? branch;
      if (_selectedBranchId != null) {
        for (final item in widget.user.branches) {
          if (item.id == _selectedBranchId) {
            branch = item;
            break;
          }
        }
      }
      final students = _selectedBranchId == null
          ? _students
          : _students
                .where((student) => student.branchId == _selectedBranchId)
                .toList();
      final assessments = await _repository.fetchAllAssessments(
        AssessmentQuery(branchId: _selectedBranchId),
      );

      final scopeLabel = branch?.name ??
          (widget.user.isAdmin ? 'Seluruh Cabang' : widget.user.branchLabel);
      final bytes = await _reportService.buildCombinedReport(
        scopeLabel: scopeLabel,
        students: students,
        assessments: assessments,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'laporan_${_slug(scopeLabel)}_'
            '${AppFormatters.isoDate(DateTime.now())}.pdf',
      );
      if (mounted) {
        _showMessage('Laporan gabungan berhasil dibuat.');
      }
    } on AssessmentRepositoryException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Laporan PDF gagal dibuat. Periksa koneksi internet dan penyimpanan '
        'perangkat Anda.',
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingCombined = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rapor & Laporan PDF')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PDF dibuat di perangkat dari data Supabase yang sudah '
                      'difilter RLS. Rapor ditandatangani musyrifah penilai '
                      'dan ${ReportSignatures.directorName}.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Rapor Individu',
              subtitle: widget.user.isMahasantri
                  ? 'Rapor pribadi berisi seluruh penilaian Anda.'
                  : 'Pilih mahasantri yang dapat Anda akses.',
            ),
            const SizedBox(height: 12),
            if (_isLoadingStudents)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              _ErrorCard(message: _loadError!, onRetry: _loadStudents)
            else if (!_isStaff)
              _buildOwnStudentCard(context)
            else if (_students.isEmpty)
              const _EmptyCard(
                message:
                    'Belum ada mahasantri aktif pada cabang yang dapat Anda '
                    'akses.',
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedStudentId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mahasantri',
                  hintText: 'Pilih mahasantri',
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
                items: [
                  for (final student in _students)
                    DropdownMenuItem(
                      value: student.id,
                      child: Text(
                        '${student.displayLabel} • ${student.branchName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedStudentId = value),
              ),
            if (!_isLoadingStudents && _loadError == null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _isGeneratingStudent || _selectedStudent == null
                    ? null
                    : _generateStudentReport,
                icon: _isGeneratingStudent
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _isGeneratingStudent
                      ? 'Menyiapkan PDF...'
                      : 'Unduh Rapor Individu',
                ),
              ),
            ],
            if (_isStaff) ...[
              const SizedBox(height: 28),
              const _SectionTitle(
                title: 'Laporan Gabungan',
                subtitle:
                    'Rekap seluruh mahasantri dan penilaian pada satu cabang '
                    'atau semua cabang yang dapat diakses.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranchId ?? _allBranches,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cakupan cabang',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _allBranches,
                    child: Text('Semua cabang yang dapat diakses'),
                  ),
                  for (final branch in widget.user.branches)
                    DropdownMenuItem(
                      value: branch.id,
                      child: Text(branch.name),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _selectedBranchId = value == _allBranches
                      ? null
                      : value,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _isGeneratingCombined
                    ? null
                    : _generateCombinedReport,
                icon: _isGeneratingCombined
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.summarize_outlined),
                label: Text(
                  _isGeneratingCombined
                      ? 'Menyiapkan laporan...'
                      : 'Unduh Laporan Gabungan',
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              widget.user.isMahasantri
                  ? 'Rapor hanya memuat data milik Anda. Mahasantri lain tidak '
                        'dapat diakses maupun diunduh.'
                  : 'Daftar mahasantri dan penilaian mengikuti penugasan '
                        'cabang. Data cabang lain tetap ditolak oleh server.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnStudentCard(BuildContext context) {
    final theme = Theme.of(context);
    final student = _selectedStudent;

    if (student == null) {
      return const _EmptyCard(
        message:
            'Akun Anda belum terhubung ke data santri. Hubungi admin agar '
            'rapor pribadi dapat dibuat.',
      );
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Text(
            widget.user.initials,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${student.nis ?? 'Tanpa NIS'} • ${student.branchName}',
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              foregroundColor: colorScheme.onErrorContainer,
              side: BorderSide(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
