class TrackerHistory {
  final String id;
  final String userId;
  final String trackerId;
  final DateTime date;
  final String type; // e.g. 'completion' or 'slip_up'
  final double? value; // Optional quantitative measure
  final String? note;

  TrackerHistory({
    required this.id,
    required this.userId,
    required this.trackerId,
    required this.date,
    this.type = 'completion',
    this.value,
    this.note,
  });

  factory TrackerHistory.fromJson(Map<String, dynamic> json) {
    return TrackerHistory(
      id: json['id'] as String,
      userId: json['userId'] as String,
      trackerId: json['trackerId'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String? ?? 'completion',
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'trackerId': trackerId,
      'date': date.toIso8601String(),
      'type': type,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
    };
  }
}
