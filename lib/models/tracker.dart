class Tracker {
  final String id;
  final String userId;
  final String summary;
  final String? description;
  final String trackerType;
  final String? rrule;
  final DateTime ruleStartDate;
  final DateTime? ruleEndDate;
  final List<DateTime> exdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tracker({
    required this.id,
    required this.userId,
    required this.summary,
    this.description,
    required this.trackerType,
    this.rrule,
    required this.ruleStartDate,
    this.ruleEndDate,
    this.exdate = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'] as String,
      userId: json['userId'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      trackerType: json['trackerType'] as String,
      rrule: json['rrule'] as String?,
      ruleStartDate: DateTime.parse(json['ruleStartDate'] as String),
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
      'summary': summary,
      'description': description,
      'trackerType': trackerType,
      'rrule': rrule,
      'ruleStartDate': ruleStartDate.toIso8601String(),
      'ruleEndDate': ruleEndDate?.toIso8601String(),
      'exdate': exdate.map((e) => e.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
