class TaskGroup {
  final String id;
  final String userId;
  final String name;
  final int colorValue;
  final String? rrule;
  final DateTime? ruleStartDate;
  final DateTime? ruleEndDate;
  final List<DateTime> exdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskGroup({
    required this.id,
    required this.userId,
    required this.name,
    this.colorValue = 4283215696,
    this.rrule,
    this.ruleStartDate,
    this.ruleEndDate,
    this.exdate = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
    return TaskGroup(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int? ?? 4283215696,
      rrule: json['rrule'] as String?,
      ruleStartDate: json['ruleStartDate'] != null ? DateTime.parse(json['ruleStartDate'] as String) : null,
      ruleEndDate: json['ruleEndDate'] != null ? DateTime.parse(json['ruleEndDate'] as String) : null,
      exdate: (json['exdate'] as List<dynamic>?)?.map((e) => DateTime.parse(e as String)).toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'colorValue': colorValue,
      'rrule': rrule,
      'ruleStartDate': ruleStartDate?.toIso8601String(),
      'ruleEndDate': ruleEndDate?.toIso8601String(),
      'exdate': exdate.map((e) => e.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
