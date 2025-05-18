class TestReport {
  final String name;
  final int count;
  final int successCount;
  final int failureCount;
  final double successRate;
  final double avgDuration;
  final int totalDuration;
  final int totalErrors;
  final int totalWarnings;

  TestReport({
    required this.name,
    required this.count,
    required this.successCount,
    required this.failureCount,
    required this.successRate,
    required this.avgDuration,
    required this.totalDuration,
    required this.totalErrors,
    required this.totalWarnings,
  });

  factory TestReport.fromJson(Map<String, dynamic> json) {
    return TestReport(
      name: json['name'],
      count: json['count'],
      successCount: json['successCount'],
      failureCount: json['failureCount'],
      successRate: json['successRate']?.toDouble() ?? 0.0,
      avgDuration: json['avgDuration']?.toDouble() ?? 0.0,
      totalDuration: json['totalDuration'] ?? 0,
      totalErrors: json['totalErrors'] ?? 0,
      totalWarnings: json['totalWarnings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'successCount': successCount,
      'failureCount': failureCount,
      'successRate': successRate,
      'avgDuration': avgDuration,
      'totalDuration': totalDuration,
      'totalErrors': totalErrors,
      'totalWarnings': totalWarnings,
    };
  }

  // Formatage de la durée moyenne pour l'affichage
  String get formattedAvgDuration {
    if (avgDuration < 1000) {
      return '${avgDuration.toStringAsFixed(2)} ms';
    } else if (avgDuration < 60000) {
      return '${(avgDuration / 1000).toStringAsFixed(2)} s';
    } else {
      final minutes = (avgDuration / 60000).floor();
      final seconds = ((avgDuration % 60000) / 1000).toStringAsFixed(2);
      return '$minutes min $seconds s';
    }
  }

  // Formatage de la durée totale pour l'affichage
  String get formattedTotalDuration {
    if (totalDuration < 1000) {
      return '$totalDuration ms';
    } else if (totalDuration < 60000) {
      return '${(totalDuration / 1000).toStringAsFixed(2)} s';
    } else if (totalDuration < 3600000) {
      final minutes = (totalDuration / 60000).floor();
      final seconds = ((totalDuration % 60000) / 1000).toStringAsFixed(2);
      return '$minutes min $seconds s';
    } else {
      final hours = (totalDuration / 3600000).floor();
      final minutes = ((totalDuration % 3600000) / 60000).floor();
      final seconds = (((totalDuration % 3600000) % 60000) / 1000).toStringAsFixed(2);
      return '$hours h $minutes min $seconds s';
    }
  }
} 