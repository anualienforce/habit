import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class HabitRepository {
  final DatabaseService _databaseService = DatabaseService();

  // Categories
  Future<List<Category>> getCategories() async {
    return await _databaseService.getCategories();
  }

  Future<Category?> getCategoryById(String id) async {
    return await _databaseService.getCategoryById(id);
  }

  Future<String> addCategory(Category category) async {
    return await _databaseService.insertCategory(category);
  }

  Future<void> updateCategory(Category category) async {
    await _databaseService.updateCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _databaseService.deleteCategory(id);
  }

  // Habits
  Future<List<Habit>> getHabits({bool? isActive}) async {
    return await _databaseService.getHabits(isActive: isActive);
  }

  Future<Habit?> getHabitById(String id) async {
    return await _databaseService.getHabitById(id);
  }

  Future<List<Habit>> getHabitsByCategory(String categoryId) async {
    return await _databaseService.getHabitsByCategory(categoryId);
  }

  Future<String> addHabit(Habit habit) async {
    return await _databaseService.insertHabit(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    await _databaseService.updateHabit(habit);
  }

  Future<void> deleteHabit(String id) async {
    await _databaseService.deleteHabit(id);
  }

  // Habit Logs
  Future<List<HabitLog>> getHabitLogs(String habitId, {DateTime? startDate, DateTime? endDate}) async {
    return await _databaseService.getHabitLogs(habitId, startDate: startDate, endDate: endDate);
  }

  Future<HabitLog?> getHabitLogByDate(String habitId, DateTime date) async {
    return await _databaseService.getHabitLogByDate(habitId, date);
  }

  Future<String> addHabitLog(HabitLog habitLog) async {
    return await _databaseService.insertHabitLog(habitLog);
  }

  Future<void> updateHabitLog(HabitLog habitLog) async {
    await _databaseService.updateHabitLog(habitLog);
  }

  Future<void> deleteHabitLog(String id) async {
    await _databaseService.deleteHabitLog(id);
  }

  // Mark habit as complete/incomplete for a specific date
  Future<bool> toggleHabitCompletion(String habitId, DateTime date) async {
    final existingLog = await getHabitLogByDate(habitId, date);
    
    if (existingLog != null) {
      // Update existing log
      final newIsCompleted = !existingLog.isCompleted;
      final updatedLog = existingLog.copyWith(isCompleted: newIsCompleted);
      await updateHabitLog(updatedLog);
      return newIsCompleted;
    } else {
      // Create new log
      final newLog = HabitLog(
        habitId: habitId,
        date: date,
        isCompleted: true,
      );
      await addHabitLog(newLog);
      return true; // New log is always marked as completed
    }
  }

  // Analytics
  Future<int> getCurrentStreak(String habitId) async {
    return await _databaseService.getCurrentStreak(habitId);
  }

  Future<int> getTotalCompletions(String habitId) async {
    return await _databaseService.getTotalCompletions(habitId);
  }

  Future<double> getCompletionRate(String habitId, {int days = 30}) async {
    return await _databaseService.getCompletionRate(habitId, days: days);
  }

  // Get habit with category information
  Future<Map<String, dynamic>> getHabitWithCategory(String habitId) async {
    final habit = await getHabitById(habitId);
    if (habit == null) return {};

    final category = await getCategoryById(habit.categoryId);
    final streak = await getCurrentStreak(habitId);
    final totalCompletions = await getTotalCompletions(habitId);
    final completionRate = await getCompletionRate(habitId);
    
    return {
      'habit': habit,
      'category': category,
      'currentStreak': streak,
      'totalCompletions': totalCompletions,
      'completionRate': completionRate,
    };
  }

  // Get all habits with their categories and stats
  Future<List<Map<String, dynamic>>> getHabitsWithDetails() async {
    final habits = await getHabits(isActive: true);
    final List<Map<String, dynamic>> habitDetails = [];

    for (final habit in habits) {
      final category = await getCategoryById(habit.categoryId);
      final streak = await getCurrentStreak(habit.id);
      final totalCompletions = await getTotalCompletions(habit.id);
      final todayLog = await getHabitLogByDate(habit.id, DateTime.now());
      
      habitDetails.add({
        'habit': habit,
        'category': category,
        'currentStreak': streak,
        'totalCompletions': totalCompletions,
        'isCompletedToday': todayLog?.isCompleted ?? false,
      });
    }

    return habitDetails;
  }

  // Get habits due today based on their schedule
  Future<List<Habit>> getHabitsDueToday() async {
    final habits = await getHabits(isActive: true);
    final today = DateTime.now();
    final todayWeekday = today.weekday;
    
    return habits.where((habit) {
      switch (habit.frequency) {
        case HabitFrequency.daily:
          return true;
        case HabitFrequency.weekly:
          return habit.weekdays.contains(todayWeekday);
        case HabitFrequency.custom:
          return habit.weekdays.contains(todayWeekday);
      }
    }).toList();
  }
}
