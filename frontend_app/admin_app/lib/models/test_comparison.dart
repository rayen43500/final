class TestPerformancePeriod {
  final int count;
  final double successRate;
  final double avgDuration;
  final int totalErrors;

  TestPerformancePeriod({
    required this.count,
    required this.successRate,
    required this.avgDuration,
    required this.totalErrors,
  });

  factory TestPerformancePeriod.fromJson(Map<String, dynamic> json) {
    return TestPerformancePeriod(
      count: json['count'] ?? 0,
      successRate: json['successRate']?.toDouble() ?? 0.0,
      avgDuration: json['avgDuration']?.toDouble() ?? 0.0,
      totalErrors: json['totalErrors'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'successRate': successRate,
      'avgDuration': avgDuration,
      'totalErrors': totalErrors,
    };
  }
}

class TestPerformanceChanges {
  final int countChange;
  final double successRateChange;
  final double durationChange;
  final int errorChange;

  TestPerformanceChanges({
    required this.countChange,
    required this.successRateChange,
    required this.durationChange,
    required this.errorChange,
  });

  factory TestPerformanceChanges.fromJson(Map<String, dynamic> json) {
    return TestPerformanceChanges(
      countChange: json['countChange'] ?? 0,
      successRateChange: json['successRateChange']?.toDouble() ?? 0.0,
      durationChange: json['durationChange']?.toDouble() ?? 0.0,
      errorChange: json['errorChange'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countChange': countChange,
      'successRateChange': successRateChange,
      'durationChange': durationChange,
      'errorChange': errorChange,
    };
  }
}

class TestComparisonItem {
  final String name;
  final TestPerformancePeriod firstPeriod;
  final TestPerformancePeriod secondPeriod;
  final TestPerformanceChanges changes;

  TestComparisonItem({
    required this.name,
    required this.firstPeriod,
    required this.secondPeriod,
    required this.changes,
  });

  factory TestComparisonItem.fromJson(Map<String, dynamic> json) {
    return TestComparisonItem(
      name: json['name'],
      firstPeriod: TestPerformancePeriod.fromJson(json['firstPeriod']),
      secondPeriod: TestPerformancePeriod.fromJson(json['secondPeriod']),
      changes: TestPerformanceChanges.fromJson(json['changes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'firstPeriod': firstPeriod.toJson(),
      'secondPeriod': secondPeriod.toJson(),
      'changes': changes.toJson(),
    };
  }
}

class TestComparison {
  final Map<String, String> firstPeriod;
  final Map<String, String> secondPeriod;
  final List<TestComparisonItem> comparison;

  TestComparison({
    required this.firstPeriod,
    required this.secondPeriod,
    required this.comparison,
  });

  factory TestComparison.fromJson(Map<String, dynamic> json) {
    return TestComparison(
      firstPeriod: Map<String, String>.from(json['firstPeriod']),
      secondPeriod: Map<String, String>.from(json['secondPeriod']),
      comparison: (json['comparison'] as List)
          .map((item) => TestComparisonItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstPeriod': firstPeriod,
      'secondPeriod': secondPeriod,
      'comparison': comparison.map((item) => item.toJson()).toList(),
    };
  }
} 