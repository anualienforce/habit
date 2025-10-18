import 'package:uuid/uuid.dart';

enum HabitFrequency {
  daily,
  weekly,
  custom,
}

class Habit {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final HabitFrequency frequency;
  final List<int> weekdays; // 1-7 for Monday-Sunday
  final int targetPerWeek;
  final int targetPerMonth;
  final DateTime? reminderTime;
  final bool isReminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Habit({
    String? id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.frequency,
    List<int>? weekdays,
    this.targetPerWeek = 7,
    this.targetPerMonth = 30,
    this.reminderTime,
    this.isReminderEnabled = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  })  : id = id ?? const Uuid().v4(),
        weekdays = weekdays ?? [1, 2, 3, 4, 5, 6, 7],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Habit copyWith({
    String? name,
    String? description,
    String? categoryId,
    HabitFrequency? frequency,
    List<int>? weekdays,
    int? targetPerWeek,
    int? targetPerMonth,
    DateTime? reminderTime,
    bool? isReminderEnabled,
    bool? isActive,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      targetPerWeek: targetPerWeek ?? this.targetPerWeek,
      targetPerMonth: targetPerMonth ?? this.targetPerMonth,
      reminderTime: reminderTime ?? this.reminderTime,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'frequency': frequency.index,
      'weekdays': weekdays.join(','),
      'targetPerWeek': targetPerWeek,
      'targetPerMonth': targetPerMonth,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'isReminderEnabled': isReminderEnabled ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      categoryId: json['categoryId'],
      frequency: HabitFrequency.values[json['frequency']],
      weekdays: json['weekdays']
          .toString()
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      targetPerWeek: json['targetPerWeek'],
      targetPerMonth: json['targetPerMonth'],
      reminderTime: json['reminderTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['reminderTime'])
          : null,
      isReminderEnabled: json['isReminderEnabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      isActive: json['isActive'] == 1,
    );
  }
}
