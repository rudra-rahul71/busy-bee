class Event {
  final String id;
  final String userId;
  final String summary;
  final String? description;
  final String? location;
  final DateTime dtstart;
  final DateTime dtend;
  final String? rrule;
  final DateTime? ruleStartDate;
  final DateTime? ruleEndDate;
  final List<DateTime> exdate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.userId,
    required this.summary,
    this.description,
    this.location,
    required this.dtstart,
    required this.dtend,
    this.rrule,
    this.ruleStartDate,
    this.ruleEndDate,
    this.exdate = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      userId: json['userId'] as String,
      summary: json['summary'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      dtstart: DateTime.parse(json['dtstart'] as String),
      dtend: DateTime.parse(json['dtend'] as String),
      rrule: json['rrule'] as String?,
      ruleStartDate: json['ruleStartDate'] != null ? DateTime.parse(json['ruleStartDate'] as String) : null,
      ruleEndDate: json['ruleEndDate'] != null ? DateTime.parse(json['ruleEndDate'] as String) : null,
      exdate: (json['exdate'] as List<dynamic>?)?.map((e) => DateTime.parse(e as String)).toList() ?? [],
      status: json['status'] as String,
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
      'location': location,
      'dtstart': dtstart.toIso8601String(),
      'dtend': dtend.toIso8601String(),
      'rrule': rrule,
      'ruleStartDate': ruleStartDate?.toIso8601String(),
      'ruleEndDate': ruleEndDate?.toIso8601String(),
      'exdate': exdate.map((e) => e.toIso8601String()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
