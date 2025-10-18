import 'package:flutter/foundation.dart' hide Category;
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/category.dart';
import '../repositories/habit_repository.dart';
import '../services/notification_service.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository _repository = HabitRepository();
  final NotificationService _notificationService = NotificationService();

  List<Habit> _habits = [];
  List<Category> _categories = [];
  List<Map<String, dynamic>> _habitsWithDetails = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Habit> get habits => _habits;
  List<Category> get categories => _categories;
  List<Map<String, dynamic>> get habitsWithDetails => _habitsWithDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadCategories(),
        loadHabits(),
      ]);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    _clearError();
    await initialize();
  }

  // Categories
  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await _repository.addCategory(category);
      await loadCategories();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _repository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Habits
  Future<void> loadHabits() async {
    try {
      _habits = await _repository.getHabits(isActive: true);
      _habitsWithDetails = await _repository.getHabitsWithDetails();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> addHabit(Habit habit) async {
    try {
      await _repository.addHabit(habit);
      
      // Schedule notifications using enhanced method
      if (habit.isReminderEnabled) {
        final success = await _notificationService.scheduleHabitNotifications(habit);
        if (!success) {
          print('⚠️ Failed to schedule notifications for new habit: ${habit.name}');
          // Don't fail the habit creation if notifications fail
        }
      }
      
      await loadHabits();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> updateHabit(Habit habit) async {
    print('🔄 HabitProvider: Starting updateHabit for ${habit.name}');
    try {
      // Update the habit in the database first
      print('💾 Updating habit in database...');
      await _repository.updateHabit(habit);
      print('✅ Database update completed');
      
      // Handle notifications separately to avoid breaking the update if notifications fail
      print('📱 Processing notifications...');
      try {
        // Use enhanced notification scheduling
        if (habit.isReminderEnabled) {
          print('⏰ Scheduling notifications for habit...');
          final success = await _notificationService.scheduleHabitNotifications(habit);
          if (!success) {
            print('⚠️ Failed to update notifications for habit: ${habit.name}');
          } else {
            print('✅ Notifications scheduled successfully');
          }
        } else {
          // Just cancel notifications if reminders are disabled
          print('🔕 Canceling notifications for habit...');
          await _notificationService.cancelHabitReminder(habit.id);
          print('🔕 Notifications disabled for habit: ${habit.name}');
        }
      } catch (notificationError) {
        print('❌ Error updating notifications for habit ${habit.name}: $notificationError');
        // Don't fail the entire update if notifications fail
      }
      
      await loadHabits();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteHabit(String id) async {
    try {
      // Cancel notifications (don't fail if this fails)
      try {
        await _notificationService.cancelHabitReminder(id);
      } catch (notificationError) {
        print('Error canceling notifications for habit $id: $notificationError');
        // Continue with deletion even if notification cancellation fails
      }
      
      await _repository.deleteHabit(id);
      await loadHabits();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Toggle habit completion
  Future<bool?> toggleHabitCompletion(String habitId, DateTime date) async {
    try {
      final isCompleted = await _repository.toggleHabitCompletion(habitId, date);
      await loadHabits(); // Refresh to update stats
      return isCompleted;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Get habit logs for calendar view
  Future<List<HabitLog>> getHabitLogs(String habitId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      return await _repository.getHabitLogs(habitId, startDate: startDate, endDate: endDate);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  // Get habit statistics
  Future<Map<String, dynamic>> getHabitStats(String habitId) async {
    try {
      final streak = await _repository.getCurrentStreak(habitId);
      final total = await _repository.getTotalCompletions(habitId);
      final rate30 = await _repository.getCompletionRate(habitId, days: 30);
      final rate7 = await _repository.getCompletionRate(habitId, days: 7);
      
      return {
        'currentStreak': streak,
        'totalCompletions': total,
        'completionRate30Days': rate30,
        'completionRate7Days': rate7,
      };
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  // Get habits by category
  List<Habit> getHabitsByCategory(String categoryId) {
    return _habits.where((habit) => habit.categoryId == categoryId).toList();
  }

  // Get habits due today
  Future<List<Habit>> getHabitsDueToday() async {
    try {
      return await _repository.getHabitsDueToday();
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  // Get category by id
  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Add habit log (for undo functionality)
  Future<void> addHabitLog(HabitLog habitLog) async {
    try {
      await _repository.addHabitLog(habitLog);
    } catch (e) {
      _setError(e.toString());
    }
  }
}
