class TestStatistic {
  final String id;
  final String testName;
  final String testType;
  final DateTime executionDate;
  final int duration;
  final bool success;
  final int errorCount;
  final int warningCount;
  final String module;
  final String environment;
  final String? executedBy;
  final Map<String, dynamic>? details;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TestStatistic({
    required this.id,
    required this.testName,
    required this.testType,
    required this.executionDate,
    required this.duration,
    required this.success,
    required this.errorCount,
    required this.warningCount,
    required this.module,
    required this.environment,
    this.executedBy,
    this.details,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TestStatistic.fromJson(Map<String, dynamic> json) {
    return TestStatistic(
      id: json['_id'],
      testName: json['testName'],
      testType: json['testType'],
      executionDate: DateTime.parse(json['executionDate']),
      duration: json['duration'],
      success: json['success'],
      errorCount: json['errorCount'] ?? 0,
      warningCount: json['warningCount'] ?? 0,
      module: json['module'],
      environment: json['environment'],
      executedBy: json['executedBy'] != null ? 
        (json['executedBy'] is String ? json['executedBy'] : json['executedBy']['_id']) : null,
      details: json['details'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'testName': testName,
      'testType': testType,
      'executionDate': executionDate.toIso8601String(),
      'duration': duration,
      'success': success,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'module': module,
      'environment': environment,
      'executedBy': executedBy,
      'details': details,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Méthode pour créer un objet de création sans ID
  Map<String, dynamic> toCreateJson() {
    return {
      'testName': testName,
      'testType': testType,
      'duration': duration,
      'success': success,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'module': module,
      'environment': environment,
      'executedBy': executedBy,
      'details': details,
      'notes': notes,
    };
  }

  // Méthode pour créer un objet de mise à jour
  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = {};
    
    // Inclure uniquement les champs modifiables
    data['testName'] = testName;
    data['testType'] = testType;
    data['duration'] = duration;
    data['success'] = success;
    data['errorCount'] = errorCount;
    data['warningCount'] = warningCount;
    data['module'] = module;
    data['environment'] = environment;
    if (executedBy != null) data['executedBy'] = executedBy;
    if (details != null) data['details'] = details;
    if (notes != null) data['notes'] = notes;
    
    return data;
  }

  // Formatage de la durée pour l'affichage
  String get formattedDuration {
    if (duration < 1000) {
      return '$duration ms';
    } else if (duration < 60000) {
      return '${(duration / 1000).toStringAsFixed(2)} s';
    } else {
      final minutes = (duration / 60000).floor();
      final seconds = ((duration % 60000) / 1000).toStringAsFixed(2);
      return '$minutes min $seconds s';
    }
  }
} 