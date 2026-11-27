import 'package:equatable/equatable.dart';

import 'assessment.dart';

/// Statistik satu cabang untuk dashboard admin/musyrifah.
class BranchStat extends Equatable {
  const BranchStat({
    required this.branchId,
    required this.branchName,
    required this.studentCount,
    required this.assessmentCount,
    this.averageScore,
  });

  final String branchId;
  final String branchName;
  final int studentCount;
  final int assessmentCount;
  final double? averageScore;

  @override
  List<Object?> get props => [
    branchId,
    branchName,
    studentCount,
    assessmentCount,
    averageScore,
  ];
}

/// Ringkasan dashboard yang sudah dihitung dari Supabase.
class DashboardStats extends Equatable {
  const DashboardStats({
    required this.totalStudents,
    required this.totalAssessments,
    required this.assessmentsThisMonth,
    required this.predicateCounts,
    required this.recentAssessments,
    required this.branchStats,
    this.averageScore,
  });

  final int totalStudents;
  final int totalAssessments;
  final int assessmentsThisMonth;
  final double? averageScore;
  final Map<Predicate, int> predicateCounts;
  final List<Assessment> recentAssessments;
  final List<BranchStat> branchStats;

  int get scoredAssessments =>
      predicateCounts.values.fold(0, (total, value) => total + value);

  static const empty = DashboardStats(
    totalStudents: 0,
    totalAssessments: 0,
    assessmentsThisMonth: 0,
    predicateCounts: {},
    recentAssessments: [],
    branchStats: [],
  );

  @override
  List<Object?> get props => [
    totalStudents,
    totalAssessments,
    assessmentsThisMonth,
    averageScore,
    predicateCounts,
    recentAssessments,
    branchStats,
  ];
}
