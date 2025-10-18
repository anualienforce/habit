// App Constants
class AppConstants {
  // App Info
  static const String appName = 'Habit Tracker';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String databaseName = 'habit_tracker.db';
  static const int databaseVersion = 1;
  
  // Notifications
  static const String habitReminderChannelId = 'habit_reminders';
  static const String habitReminderChannelName = 'Habit Reminders';
  static const String habitReminderChannelDesc = 'Reminders for your daily habits';
  
  static const String instantNotificationChannelId = 'instant_notifications';
  static const String instantNotificationChannelName = 'Instant Notifications';
  static const String instantNotificationChannelDesc = 'Instant notifications for app events';
  
  // Shared Preferences Keys
  static const String themeKey = 'theme_mode';
  static const String firstLaunchKey = 'first_launch';
  static const String notificationPermissionKey = 'notification_permission';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 20.0;
  
  // Analytics Time Periods
  static const int defaultAnalyticsDays = 30;
  static const int weeklyAnalyticsDays = 7;
  static const int quarterlyAnalyticsDays = 90;
  
  // Habit Frequency Limits
  static const int maxHabitsPerDay = 20;
  static const int maxTargetPerWeek = 7;
  static const int maxTargetPerMonth = 31;
  
  // Notification Timing
  static const int snoozeMinutes = 15;
  static const int defaultReminderHour = 9;
  static const int defaultReminderMinute = 0;
}

// Color Constants
class AppColors {
  // Category Default Colors
  static const int categoryBlue = 0xFF2196F3;
  static const int categoryGreen = 0xFF4CAF50;
  static const int categoryOrange = 0xFFFF9800;
  static const int categoryRed = 0xFFF44336;
  static const int categoryPurple = 0xFF9C27B0;
  static const int categoryTeal = 0xFF009688;
  static const int categoryPink = 0xFFE91E63;
  static const int categoryIndigo = 0xFF3F51B5;
  static const int categoryAmber = 0xFFFFC107;
  static const int categoryCyan = 0xFF00BCD4;
}

// Text Constants
class AppTexts {
  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Try Again';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String undo = 'Undo';
  
  // Habits
  static const String habits = 'Habits';
  static const String addHabit = 'Add Habit';
  static const String editHabit = 'Edit Habit';
  static const String habitName = 'Habit Name';
  static const String habitDescription = 'Description (Optional)';
  static const String deleteHabitTitle = 'Delete Habit';
  static const String habitDeleted = 'Habit deleted';
  static const String habitRestored = 'Habit restored';
  static const String habitCompleted = 'Great job! Keep it up! 🎉';
  
  // Categories
  static const String categories = 'Categories';
  static const String addCategory = 'Add Category';
  static const String editCategory = 'Edit Category';
  static const String categoryName = 'Category Name';
  static const String manageCategories = 'Manage Categories';
  
  // Statistics
  static const String statistics = 'Statistics';
  static const String currentStreak = 'Current Streak';
  static const String totalCompletions = 'Total Done';
  static const String completionRate = 'Completion Rate';
  static const String bestStreak = 'Best Streak';
  
  // Settings
  static const String settings = 'Settings';
  static const String appearance = 'Appearance';
  static const String theme = 'Theme';
  static const String notifications = 'Notifications';
  static const String about = 'About';
  
  // Empty States
  static const String noHabits = 'No habits yet';
  static const String createFirstHabit = 'Create your first habit to get started!';
  static const String noStatistics = 'No Statistics Yet';
  static const String createHabitsForStats = 'Create some habits to see your progress!';
}
