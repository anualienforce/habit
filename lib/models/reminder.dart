enum ReminderRepeat {
  none,
  daily,
  weekly,
  custom,
}

class Reminder {
  final String id;
  final String habitId;
  final DateTime dateTime;
  final String title;
  final String message;
  final ReminderRepeat repeat;
  final bool isActive;

  Reminder({
    required this.id,
    required this.habitId,
    required this.dateTime,
    required this.title,
    required this.message,
    this.repeat = ReminderRepeat.none,
    this.isActive = true,
  });

  Reminder copyWith({
    String? id,
    String? habitId,
    DateTime? dateTime,
    String? title,
    String? message,
    ReminderRepeat? repeat,
    bool? isActive,
  }) {
    return Reminder(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      dateTime: dateTime ?? this.dateTime,
      title: title ?? this.title,
      message: message ?? this.message,
      repeat: repeat ?? this.repeat,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'dateTime': dateTime.toIso8601String(),
      'title': title,
      'message': message,
      'repeat': repeat.toString().split('.').last,
      'isActive': isActive,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      repeat: ReminderRepeat.values.firstWhere(
        (e) => e.toString().split('.').last == json['repeat'],
        orElse: () => ReminderRepeat.none,
      ),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder &&
        other.id == id &&
        other.habitId == habitId &&
        other.dateTime == dateTime &&
        other.title == title &&
        other.message == message &&
        other.repeat == repeat &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      habitId,
      dateTime,
      title,
      message,
      repeat,
      isActive,
    );
  }

  @override
  String toString() {
    return 'Reminder(id: $id, habitId: $habitId, title: $title, dateTime: $dateTime, repeat: $repeat, isActive: $isActive)';
  }
}
