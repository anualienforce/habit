import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/habit.dart';
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize time zones
    tz_data.initializeTimeZones();

    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      // Use the app's launcher icon as the default notification icon
      'resource://mipmap/ic_launcher',
      [
        NotificationChannel(
          channelGroupKey: 'habit_reminder_channel_group',
          channelKey: 'habit_reminder_channel',
          channelName: 'Habit Reminders',
          channelDescription: 'Notifications for habit reminders',
          defaultColor: Colors.blueAccent,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          playSound: true,
          enableVibration: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'habit_reminder_channel_group',
          channelGroupName: 'Habit Reminder group',
        ),
      ],
      debug: true,
    );

    // Register unified callbacks
    AwesomeNotifications().setListeners(
      onNotificationCreatedMethod: (ReceivedNotification n) async {
        debugPrint('🔔 Habit notification created: id=${n.id}');
        return;
      },
      onNotificationDisplayedMethod: (ReceivedNotification n) async {
        debugPrint('👀 Habit notification displayed: id=${n.id}');
        return;
      },
      onActionReceivedMethod: (ReceivedAction a) async {
        final habitId = a.payload?['habitId'];
        debugPrint('➡️ Habit notification action (tap/button): habitId=$habitId');
        // TODO: navigate to habit detail page, e.g.:
        // navigatorKey.currentState?.pushNamed('/habitDetail', arguments: habitId);
        return;
      },
    );

    _isInitialized = true;
    return;
  }

  Future<bool> requestPermissions() async {
    return AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> scheduleHabitReminder(Habit habit) async {
    await initialize();
    bool hasPermission = await requestPermissions();
    
    if (!hasPermission) {
      debugPrint('📛 Notification permission denied');
      return;
    }

    if (!habit.isReminderEnabled || habit.reminderTime == null) {
      return;
    }

    final int notificationId = habit.id.hashCode;
    
    // Create reminder from habit
    final reminder = Reminder(
      id: habit.id,
      habitId: habit.id,
      dateTime: habit.reminderTime!,
      title: habit.name,
      message: habit.description ?? 'Time to work on your habit!',
      repeat: _getRepeatFromHabitFrequency(habit.frequency),
    );

    final DateTime scheduledTime = _nextInstanceOfReminderTime(
        reminder.dateTime, reminder.repeat, habit.weekdays);

    // Schedule the reminder
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'habit_reminder_channel',
        title: reminder.title,
        body: reminder.message,
        notificationLayout: NotificationLayout.Default,
        payload: {'habitId': reminder.habitId},
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        largeIcon: 'resource://mipmap/ic_launcher',
        color: Colors.blueAccent,
      ),
      schedule: _createSchedule(scheduledTime, reminder.repeat, habit.weekdays),
    );

    debugPrint(
      '📅 Scheduled habit reminder [${reminder.title}] for $scheduledTime (id=$notificationId)',
    );
    return;
  }

  ReminderRepeat _getRepeatFromHabitFrequency(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return ReminderRepeat.daily;
      case HabitFrequency.weekly:
        return ReminderRepeat.weekly;
      case HabitFrequency.custom:
        return ReminderRepeat.custom; // Custom will use weekdays
    }
  }

  NotificationSchedule _createSchedule(
      DateTime dt, ReminderRepeat repeat, List<int> weekdays) {
    final now = DateTime.now();
    
    // If the date is in the past, schedule for now + 1 minute for non-repeating events
    if (repeat == ReminderRepeat.none && dt.isBefore(now)) {
      final newTime = now.add(const Duration(minutes: 1));
      debugPrint('⚠️ Adjusted past date to: $newTime');
      
      return NotificationCalendar(
        year: newTime.year,
        month: newTime.month,
        day: newTime.day,
        hour: newTime.hour,
        minute: newTime.minute,
        second: 0,
        preciseAlarm: true,
        allowWhileIdle: true,
        repeats: false,
      );
    }
    
    switch (repeat) {
      case ReminderRepeat.daily:
        return NotificationCalendar(
          hour: dt.hour,
          minute: dt.minute,
          second: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        );
      case ReminderRepeat.weekly:
        return NotificationCalendar(
          weekday: dt.weekday,
          hour: dt.hour,
          minute: dt.minute,
          second: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        );
      case ReminderRepeat.custom:
        // For custom frequency, use the first weekday
        int targetWeekday = weekdays.isNotEmpty ? weekdays.first : dt.weekday;
        return NotificationCalendar(
          weekday: targetWeekday,
          hour: dt.hour,
          minute: dt.minute,
          second: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        );
      case ReminderRepeat.none:
        return NotificationCalendar(
          year: dt.year,
          month: dt.month,
          day: dt.day,
          hour: dt.hour,
          minute: dt.minute,
          second: 0,
          preciseAlarm: true,
          allowWhileIdle: true,
          repeats: false,
        );
    }
  }

  DateTime _nextInstanceOfReminderTime(
      DateTime originalTime, ReminderRepeat repeat, List<int> weekdays) {
    final now = DateTime.now();
    DateTime scheduled = DateTime(
      now.year,
      now.month, 
      now.day,
      originalTime.hour,
      originalTime.minute,
    );

    // If non-recurring in the past, bump to next minute
    if (repeat == ReminderRepeat.none && scheduled.isBefore(now)) {
      scheduled = now.add(const Duration(minutes: 1));
      return scheduled;
    }

    // If recurring or still past, compute next occurrence
    if (scheduled.isBefore(now)) {
      switch (repeat) {
        case ReminderRepeat.daily:
          scheduled = scheduled.add(const Duration(days: 1));
          break;
        case ReminderRepeat.weekly:
          // For weekly, use the original weekday
          while (scheduled.weekday != originalTime.weekday || scheduled.isBefore(now)) {
            scheduled = scheduled.add(const Duration(days: 1));
          }
          break;
        case ReminderRepeat.custom:
          // Find next occurrence based on weekdays
          int targetWeekday = weekdays.isNotEmpty ? weekdays.first : originalTime.weekday;
          while (scheduled.weekday != targetWeekday || scheduled.isBefore(now)) {
            scheduled = scheduled.add(const Duration(days: 1));
          }
          break;
        case ReminderRepeat.none:
          break;
      }
    }

    return scheduled;
  }

  Future<void> scheduleMultipleHabitReminders(Habit habit) async {
    await initialize();
    bool hasPermission = await requestPermissions();
    
    if (!hasPermission) {
      debugPrint('📛 Notification permission denied');
      return;
    }

    if (!habit.isReminderEnabled || habit.reminderTime == null) {
      return;
    }

    // For custom frequency with multiple weekdays, schedule separate notifications
    if (habit.frequency == HabitFrequency.custom && habit.weekdays.length > 1) {
      for (int i = 0; i < habit.weekdays.length; i++) {
        final int notificationId = '${habit.id}_$i'.hashCode;
        final weekday = habit.weekdays[i];
        
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: 'habit_reminder_channel',
            title: habit.name,
            body: habit.description ?? 'Time to work on your habit!',
            notificationLayout: NotificationLayout.Default,
            payload: {'habitId': habit.id},
            wakeUpScreen: true,
            category: NotificationCategory.Reminder,
            largeIcon: 'resource://mipmap/ic_launcher',
            color: Colors.blueAccent,
          ),
          schedule: NotificationCalendar(
            weekday: weekday,
            hour: habit.reminderTime!.hour,
            minute: habit.reminderTime!.minute,
            second: 0,
            repeats: true,
            preciseAlarm: true,
            allowWhileIdle: true,
          ),
        );
        
        debugPrint(
          '📅 Scheduled habit reminder [${habit.name}] for weekday $weekday (id=$notificationId)',
        );
      }
    } else {
      // For daily/weekly single reminders, use the main method
      await scheduleHabitReminder(habit);
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await AwesomeNotifications().cancel(habitId.hashCode);
    
    // Also cancel any weekday-specific reminders for custom frequency
    for (int i = 0; i < 7; i++) {
      await AwesomeNotifications().cancel('${habitId}_$i'.hashCode);
    }
    
    debugPrint('🚫 Cancelled habit reminder for habit: $habitId');
    return;
  }

  Future<void> cancelAllReminders() async {
    await AwesomeNotifications().cancelAll();
    debugPrint('🚫 Cancelled all habit reminders');
    return;
  }

  Future<List<NotificationModel>> getPendingNotifications() async {
    final list = await AwesomeNotifications().listScheduledNotifications();
    return list;
  }

  // Legacy method compatibility for existing code
  Future<void> scheduleNotification(Habit habit) async {
    return scheduleMultipleHabitReminders(habit);
  }

  Future<void> cancelNotification(String habitId) async {
    return cancelHabitReminder(habitId);
  }

  Future<void> rescheduleNotifications(List<Habit> habits) async {
    await cancelAllReminders();
    
    for (final habit in habits) {
      if (habit.isReminderEnabled && habit.reminderTime != null) {
        await scheduleMultipleHabitReminders(habit);
      }
    }
    
    debugPrint('🔄 Rescheduled ${habits.length} habit reminders');
  }

  // Additional methods for compatibility with existing code  
  Future<bool> scheduleHabitNotifications(dynamic habitOrList) async {
    try {
      if (habitOrList is Habit) {
        // Handle single habit
        if (habitOrList.isReminderEnabled && habitOrList.reminderTime != null) {
          await scheduleMultipleHabitReminders(habitOrList);
        }
        return true;
      } else if (habitOrList is List<Habit>) {
        // Handle list of habits
        for (final habit in habitOrList) {
          if (habit.isReminderEnabled && habit.reminderTime != null) {
            await scheduleMultipleHabitReminders(habit);
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error scheduling habit notifications: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getNotificationStatus() async {
    await initialize();
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    final pendingList = await getPendingNotifications();
    
    return {
      'isAllowed': isAllowed,
      'pendingCount': pendingList.length,
      'isInitialized': _isInitialized,
    };
  }

  Future<void> testNotification() async {
    await initialize();
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999999,
        channelKey: 'habit_reminder_channel',
        title: 'Test Notification',
        body: 'This is a test notification from your habit tracker!',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
        largeIcon: 'resource://mipmap/ic_launcher',
        color: Colors.blueAccent,
      ),
    );
  }

  Future<void> printDebugInfo() async {
    final status = await getNotificationStatus();
    debugPrint('🔍 Notification Debug Info: $status');
  }

  Future<Map<String, dynamic>> getDebugInfo() async {
    return await getNotificationStatus();
  }
}
