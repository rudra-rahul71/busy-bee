import '../core/utils/date_utils.dart';

class Tracker {
  final String id;
  final String userId;
  final String summary;
  final String trackerType;
  final String? rrule;
  final DateTime ruleStartDate;
  final DateTime? ruleEndDate;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastEventDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tracker({
    required this.id,
    required this.userId,
    required this.summary,
    required this.trackerType,
    this.rrule,
    required this.ruleStartDate,
    this.ruleEndDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastEventDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Tracker copyWith({
    String? id,
    String? userId,
    String? summary,
    String? trackerType,
    String? rrule,
    DateTime? ruleStartDate,
    DateTime? ruleEndDate,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastEventDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tracker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      summary: summary ?? this.summary,
      trackerType: trackerType ?? this.trackerType,
      rrule: rrule ?? this.rrule,
      ruleStartDate: ruleStartDate ?? this.ruleStartDate,
      ruleEndDate: ruleEndDate ?? this.ruleEndDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastEventDate: lastEventDate ?? this.lastEventDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'] as String,
      userId: json['userId'] as String,
      summary: json['summary'] as String,
      trackerType: json['trackerType'] as String,
      rrule: json['rrule'] as String?,
      ruleStartDate: AppDateParser.parseDateOnly(json['ruleStartDate']),
      ruleEndDate: AppDateParser.parseNullableDateOnly(json['ruleEndDate']),
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastEventDate: AppDateParser.parseNullableDateOnly(json['lastEventDate']),
      createdAt: AppDateParser.parseDateTime(json['createdAt']),
      updatedAt: AppDateParser.parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'summary': summary,
      'trackerType': trackerType,
      'rrule': rrule,
      'ruleStartDate': AppDateParser.formatDateOnly(ruleStartDate),
      if (ruleEndDate != null)
        'ruleEndDate': AppDateParser.formatDateOnly(ruleEndDate!),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastEventDate != null)
        'lastEventDate': AppDateParser.formatDateOnly(lastEventDate!),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }
}
