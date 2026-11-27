import 'dart:async';

import 'package:flutter/material.dart';

import '../../assessment/data/assessment_repository.dart';
import '../../assessment/data/supabase_assessment_repository.dart';
import '../../assessment/domain/academic_period.dart';
import '../../assessment/domain/assessment.dart';
import '../../assessment/presentation/widgets/assessment_list_tile.dart';
import '../../auth/domain/app_user.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import 'assessment_detail_sheet.dart';

/// Tab Riwayat: daftar penilaian dengan pencarian, filter kategori, cabang,
/// dan periode akademik. Data dimuat bertahap (pagination) agar riwayat besar
/// tetap ringan.
const String _allBranches = '__all_branches__';
const String _allPeriods = '__all_periods__';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key, required this.user, this.repository});

  final AppUser user;
  final AssessmentRepository? repository;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  static const int _pageSize = 50;

  late final AssessmentRepository _repository;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<Assessment> _assessments = const [];
  List<AcademicPeriod> _periods = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _didApplyDefaultPeriod = false;
  String? _errorMessage;
  String? _moreError;
  int _requestToken = 0;
  String _searchQuery = '';
  AssessmentCategory? _selectedCategory;
  String? _selectedBranchId;
  String? _selectedPeriodId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SupabaseAssessmentRepository();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  AcademicPeriod? get _selectedPeriod {
    for (final period in _periods) {
      if (period.id == _selectedPeriodId) {
        return period;
      }
    }
    return null;
  }

  AssessmentQuery _query({required int offset}) {
    final period = _selectedPeriod;
    final search = _searchQuery.trim();
    return AssessmentQuery(
      branchId: _selectedBranchId,
      category: _selectedCategory,
      from: period?.startDate,
      to: period?.endDate,
      search: search.isEmpty ? null : search,
      limit: _pageSize,
      offset: offset,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter < 400) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    _searchDebounce?.cancel();
    final token = ++_requestToken;

    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _moreError = null;
      _errorMessage = null;
    });

    try {
      if (_periods.isEmpty) {
        _periods = await _repository.fetchAcademicPeriods();
      }

      if (!_didApplyDefaultPeriod && _periods.isNotEmpty) {
        _didApplyDefaultPeriod = true;
        _selectedPeriodId = AcademicPeriod.defaultOf(_periods)?.id;
      }

      final assessments = await _repository.fetchAssessments(
        _query(offset: 0),
      );

      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _assessments = assessments;
        _hasMore = assessments.length == _pageSize;
      });
    } on AssessmentRepositoryException catch (error) {
      if (mounted && token == _requestToken) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted && token == _requestToken) {
        setState(
          () => _errorMessage =
              'Riwayat gagal dimuat. Periksa koneksi internet Anda.',
        );
      }
    } finally {
      if (mounted && token == _requestToken) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final token = _requestToken;
    setState(() {
      _isLoadingMore = true;
      _moreError = null;
    });

    try {
      final page = await _repository.fetchAssessments(
        _query(offset: _assessments.length),
      );

      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _assessments = [..._assessments, ...page];
        _hasMore = page.length == _pageSize;
      });
    } on AssessmentRepositoryException catch (error) {
      if (mounted && token == _requestToken) {
        setState(() => _moreError = error.message);
      }
    } catch (_) {
      if (mounted && token == _requestToken) {
        setState(
          () => _moreError =
              'Sebagian riwayat gagal dimuat. Periksa koneksi internet Anda.',
        );
      }
    } finally {
      if (mounted && token == _requestToken) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _openDetail(Assessment assessment) async {
    final changed = await showAssessmentDetailSheet(
      context,
      user: widget.user,
      assessment: assessment,
      repository: _repository,
    );

    if (changed == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showBranchFilter = widget.user.branches.length > 1;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat Penilaian',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.user.isMahasantri
                            ? 'Seluruh penilaian milik Anda.'
                            : 'Penilaian pada cabang yang dapat Anda akses.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Muat ulang riwayat',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIS mahasantri',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _clearSearch();
                        },
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Hapus pencarian',
                      ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: _selectedCategory == null,
                    onTap: () {
                      setState(() => _selectedCategory = null);
                      _load();
                    },
                  ),
                  for (final category in AssessmentCategory.values) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: category.label,
                      selected: _selectedCategory == category,
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        _load();
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (showBranchFilter) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranchId ?? _allBranches,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filter cabang',
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
                onChanged: (value) {
                  setState(
                    () => _selectedBranchId = value == _allBranches
                        ? null
                        : value,
                  );
                  _load();
                },
              ),
            ],
            if (_periods.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedPeriodId ?? _allPeriods,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Filter periode akademik',
                  prefixIcon: Icon(Icons.date_range_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _allPeriods,
                    child: Text('Semua periode'),
                  ),
                  for (final period in _periods)
                    DropdownMenuItem(
                      value: period.id,
                      child: Text(period.name),
                    ),
                ],
                onChanged: (value) {
                  setState(
                    () => _selectedPeriodId = value == _allPeriods
                        ? null
                        : value,
                  );
                  _load();
                },
              ),
            ],
            const SizedBox(height: 18),
            if (!_isLoading && _errorMessage == null && _assessments.isNotEmpty)
              Text(
                'Menampilkan ${_assessments.length} penilaian'
                '${_searchQuery.trim().isEmpty ? '' : ' sesuai pencarian'}.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            if (_isLoading)
              const ListSkeleton()
            else if (_errorMessage != null)
              _ErrorCard(message: _errorMessage!, onRetry: _load)
            else if (_assessments.isEmpty)
              EmptyState(
                icon: Icons.inbox_outlined,
                title: _searchQuery.trim().isEmpty
                    ? 'Belum ada penilaian'
                    : 'Tidak ditemukan',
                message: _searchQuery.trim().isEmpty
                    ? 'Belum ada penilaian pada filter ini. Coba ubah kategori, '
                          'cabang, atau periode.'
                    : 'Tidak ada mahasantri yang cocok dengan pencarian '
                          '"${_searchQuery.trim()}".',
              )
            else ...[
              for (var index = 0; index < _assessments.length; index++) ...[
                AssessmentListTile(
                  assessment: _assessments[index],
                  onTap: () => _openDetail(_assessments[index]),
                ),
                if (index != _assessments.length - 1)
                  const SizedBox(height: 10),
              ],
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_moreError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _LoadMoreError(
                    message: _moreError!,
                    onRetry: _loadMore,
                  ),
                )
              else if (!_hasMore && _assessments.length > _pageSize)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Semua penilaian sudah ditampilkan.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    setState(() => _searchQuery = '');
    _load();
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

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Muat lagi'),
        ),
      ],
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
