import 'package:uuid/uuid.dart';

class HabitLog {
  final String id;
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;

  HabitLog({
    String? id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  HabitLog copyWith({
    bool? isCompleted,
    String? notes,
  }) {
    return HabitLog(
      id: id,
      habitId: habitId,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'],
      habitId: json['habitId'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      isCompleted: json['isCompleted'] == 1,
      notes: json['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  /// Get date without time for comparison
  DateTime get dateOnly {
    return DateTime(date.year, date.month, date.day);
  }
}
