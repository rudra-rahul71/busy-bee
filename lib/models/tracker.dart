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
  final int clientOffsetHours;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final DateTime? lastSlipUpDate;
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
    this.clientOffsetHours = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.lastSlipUpDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Tracker copyWith({
    String? id,
    String? userId,
    String? summary,
    String? description,
    String? trackerType,
    String? rrule,
    DateTime? ruleStartDate,
    DateTime? ruleEndDate,
    List<DateTime>? exdate,
    int? clientOffsetHours,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    DateTime? lastSlipUpDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tracker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      trackerType: trackerType ?? this.trackerType,
      rrule: rrule ?? this.rrule,
      ruleStartDate: ruleStartDate ?? this.ruleStartDate,
      ruleEndDate: ruleEndDate ?? this.ruleEndDate,
      exdate: exdate ?? this.exdate,
      clientOffsetHours: clientOffsetHours ?? this.clientOffsetHours,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      lastSlipUpDate: lastSlipUpDate ?? this.lastSlipUpDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'] as String,
      userId: json['userId'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      trackerType: json['trackerType'] as String,
      rrule: json['rrule'] as String?,
      ruleStartDate: DateTime.parse(json['ruleStartDate'] as String),
      ruleEndDate: json['ruleEndDate'] != null
          ? DateTime.parse(json['ruleEndDate'] as String)
          : null,
      exdate:
          (json['exdate'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
      clientOffsetHours: json['clientOffsetHours'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'] as String)
          : null,
      lastSlipUpDate: json['lastSlipUpDate'] != null
          ? DateTime.parse(json['lastSlipUpDate'] as String)
          : null,
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
      'clientOffsetHours': clientOffsetHours,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastCompletedDate != null)
        'lastCompletedDate': lastCompletedDate!.toIso8601String(),
      if (lastSlipUpDate != null)
        'lastSlipUpDate': lastSlipUpDate!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
