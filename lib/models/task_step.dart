class TaskStep {
  final String id;
  final String title;
  final bool isCompleted;
  final int? durationSeconds;

  TaskStep({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.durationSeconds,
  });

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      durationSeconds: json['durationSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
    };
  }

  TaskStep copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? durationSeconds,
  }) {
    return TaskStep(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
