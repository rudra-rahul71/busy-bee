import 'task_step.dart';

class Task {
  final String id;
  final String userId;
  final String? groupId;
  final String summary;
  final String? description;
  final String? location;
  final List<TaskStep> steps;
  final DateTime? dtstart;
  final DateTime? due;
  final String status;
  final DateTime? completedAt;
  final String? rrule;
  final DateTime? ruleStartDate;
  final DateTime? ruleEndDate;
  final List<DateTime> exdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.userId,
    this.groupId,
    required this.summary,
    this.description,
    this.location,
    required this.steps,
    this.dtstart,
    this.due,
    required this.status,
    this.completedAt,
    this.rrule,
    this.ruleStartDate,
    this.ruleEndDate,
    this.exdate = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['userId'] as String,
      groupId: json['groupId'] as String?,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => TaskStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dtstart: json['dtstart'] != null
          ? DateTime.parse(json['dtstart'] as String)
          : null,
      due: json['due'] != null ? DateTime.parse(json['due'] as String) : null,
      status: json['status'] as String,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      rrule: json['rrule'] as String?,
      ruleStartDate: json['ruleStartDate'] != null
          ? DateTime.parse(json['ruleStartDate'] as String)
          : null,
      ruleEndDate: json['ruleEndDate'] != null
          ? DateTime.parse(json['ruleEndDate'] as String)
          : null,
      exdate:
          (json['exdate'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'groupId': groupId,
      'summary': summary,
      'description': description,
      'location': location,
      'steps': steps.map((s) => s.toJson()).toList(),
      'dtstart': dtstart?.toIso8601String(),
      'due': due?.toIso8601String(),
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'rrule': rrule,
      'ruleStartDate': ruleStartDate?.toIso8601String(),
      'ruleEndDate': ruleEndDate?.toIso8601String(),
      'exdate': exdate.map((e) => e.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
