import '../core/utils/date_utils.dart';

class TrackerHistory {
  final String id;
  final String userId;
  final String trackerId;
  final DateTime date;
  final String type; // e.g. 'completion' or 'slip_up'
  final double? value; // Optional quantitative measure

  TrackerHistory({
    required this.id,
    required this.userId,
    required this.trackerId,
    required this.date,
    this.type = 'completion',
    this.value,
  });

  factory TrackerHistory.fromJson(Map<String, dynamic> json) {
    return TrackerHistory(
      id: json['id'] as String,
      userId: json['userId'] as String,
      trackerId: json['trackerId'] as String,
      date: AppDateParser.parseDateOnly(json['date']),
      type: json['type'] as String? ?? 'completion',
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'trackerId': trackerId,
      'date': AppDateParser.formatDateOnly(date),
      'type': type,
      if (value != null) 'value': value,
    };
  }
}
