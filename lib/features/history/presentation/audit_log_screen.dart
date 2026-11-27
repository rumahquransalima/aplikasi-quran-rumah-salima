import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../assessment/data/assessment_repository.dart';
import '../../assessment/data/supabase_assessment_repository.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/domain/audit_log_entry.dart';

/// Daftar audit log global (khusus admin, ditegakkan RLS).
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key, this.repository});

  final AssessmentRepository? repository;

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late final AssessmentRepository _repository;
  List<AuditLogEntry> _logs = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _actionFilter;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseAssessmentRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await _repository.fetchAuditLogs(limit: 200);
      if (mounted) {
        setState(() => _logs = logs);
      }
    } on AssessmentRepositoryException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<AuditLogEntry> get _visible {
    if (_actionFilter == null) {
      return _logs;
    }
    return _logs
        .where((log) => log.action == _actionFilter)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                'Jejak koreksi dan penghapusan penilaian dari seluruh cabang. '
                'Log bersifat append-only dan tidak dapat diubah dari aplikasi.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: _actionFilter == null,
                      onTap: () => setState(() => _actionFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Koreksi',
                      selected: _actionFilter == 'UPDATE',
                      onTap: () => setState(() => _actionFilter = 'UPDATE'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Hapus',
                      selected: _actionFilter == 'DELETE',
                      onTap: () => setState(() => _actionFilter = 'DELETE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                _ErrorCard(message: _errorMessage!, onRetry: _load)
              else if (visible.isEmpty)
                _EmptyCard(
                  message: _logs.isEmpty
                      ? 'Belum ada koreksi atau penghapusan penilaian.'
                      : 'Tidak ada log dengan filter ini.',
                )
              else
                for (final log in visible) ...[
                  _AuditLogCard(log: log),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final AuditLogEntry log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = log.isDelete ? log.oldData : log.newData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  log.isDelete
                      ? Icons.delete_outline_rounded
                      : Icons.edit_outlined,
                  size: 18,
                  color: log.isDelete
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  log.isDelete ? 'Penghapusan' : 'Koreksi',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormatters.shortDateTime(log.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Oleh ${log.changedByName ?? 'Pengguna'} • '
              'Penilaian ${_shortId(log.assessmentId)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (data != null) ...[
              const SizedBox(height: 6),
              Text(
                _describeData(data),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (log.correctionReason != null) ...[
              const SizedBox(height: 6),
              Text(
                'Alasan: ${log.correctionReason}',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ],
            if (!log.isDelete && log.oldData != null && log.newData != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _describeChanges(log.oldData!, log.newData!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortId(String? id) {
    if (id == null || id.length < 8) {
      return id ?? '-';
    }
    return '#${id.substring(0, 8)}';
  }

  String _describeData(Map<String, dynamic> data) {
    final category = AssessmentCategory.fromValue(
      data['category'] as String?,
    );
    final predicate = Predicate.tryParse(data['predicate'] as String?);
    final date = data['assessment_date'] is String
        ? DateTime.tryParse(data['assessment_date'] as String)
        : null;

    return [
      category.label,
      if (date != null) AppFormatters.shortDate(date),
      if (predicate != null) predicate.label,
      if (data['numeric_score'] != null)
        'Nilai ${AppFormatters.score((data['numeric_score'] as num?)?.toDouble())}',
    ].join(' • ');
  }

  String _describeChanges(
    Map<String, dynamic> oldData,
    Map<String, dynamic> newData,
  ) {
    const labels = {
      'category': 'Kategori',
      'assessment_date': 'Tanggal',
      'predicate': 'Predikat',
      'numeric_score': 'Nilai',
      'juz_start': 'Juz dari',
      'juz_end': 'Juz sampai',
      'notes': 'Catatan',
    };

    final changes = <String>[];
    for (final entry in labels.entries) {
      final before = oldData[entry.key];
      final after = newData[entry.key];
      if (before != after) {
        changes.add(
          '${entry.value}: ${_value(before)} → ${_value(after)}',
        );
      }
    }

    return changes.isEmpty ? 'Tidak ada perubahan field.' : changes.join('\n');
  }

  String _value(Object? value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return '(kosong)';
    }
    return '$value';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? colorScheme.onPrimaryContainer : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
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
      padding: const EdgeInsets.all(18),
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
  final Future<void> Function() onRetry;

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
