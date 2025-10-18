import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../models/habit_log.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<DateTime> _selectedDay;
  late final ValueNotifier<DateTime> _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String? _selectedHabitId;
  Map<String, List<HabitLog>> _habitLogs = {};

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = ValueNotifier(today);
    _focusedDay = ValueNotifier(today);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabitLogs();
    });
  }

  @override
  void dispose() {
    _selectedDay.dispose();
    _focusedDay.dispose();
    super.dispose();
  }

  Future<void> _loadHabitLogs() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    
    final logs = <String, List<HabitLog>>{};
    for (final habit in habits) {
      final habitLogs = await habitProvider.getHabitLogs(
        habit.id,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );
      logs[habit.id] = habitLogs;
    }
    
    setState(() {
      _habitLogs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedHabitId = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) {
              final habitProvider = Provider.of<HabitProvider>(context, listen: false);
              final habits = habitProvider.habits;
              
              return [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('All Habits'),
                ),
                ...habits.map((habit) => PopupMenuItem(
                  value: habit.id,
                  child: Text(habit.name),
                )),
              ];
            },
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          // Reload logs whenever habits change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadHabitLogs();
          });
          
          return Column(
            children: [
              // Calendar
              Card(
                margin: const EdgeInsets.all(16),
                child: TableCalendar<HabitLog>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay.value,
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                    holidayTextStyle: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                    markerDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    // Customize markers to show different colors for completed vs pending
                    markersMaxCount: 3,
                    canMarkersOverflow: true,
                  ),
                  calendarBuilders: CalendarBuilders<HabitLog>(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      
                      // Count completed and pending habits
                      int completed = events.where((e) => e.isCompleted).length;
                      int pending = events.where((e) => !e.isCompleted).length;
                      
                      List<Widget> markers = [];
                      
                      // Add completed marker
                      if (completed > 0) {
                        markers.add(
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: completed > 1 ? Center(
                              child: Text(
                                completed.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ) : null,
                          ),
                        );
                      }
                      
                      // Add pending marker
                      if (pending > 0) {
                        markers.add(
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: pending > 1 ? Center(
                              child: Text(
                                pending.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ) : null,
                          ),
                        );
                      }
                      
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: markers,
                      );
                    },
                  ),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay.value = focusedDay;
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay.value, day);
                  },
                ),
              ),
              
              // Selected day habits
              Expanded(
                child: ValueListenableBuilder<DateTime>(
                  valueListenable: _selectedDay,
                  builder: (context, selectedDay, _) {
                    final dayLogs = _getLogsForDay(selectedDay);
                    
                    if (dayLogs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No habits for ${DateFormat('MMM d, y').format(selectedDay)}',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a day with habits to see the details',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: dayLogs.length,
                      itemBuilder: (context, index) {
                        final log = dayLogs[index];
                        final habit = habitProvider.habits
                            .firstWhere((h) => h.id == log.habitId);
                        final category = habitProvider.getCategoryById(habit.categoryId);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: category?.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                (category != null)
                                    ? (kCategoryIconConstants[category.id] ??
                                    kCategoryIconConstants[category.id] ?? Icons.task_alt)
                                    : Icons.task_alt,
                                color: category?.color ?? theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(habit.name),
                            subtitle: log.notes != null && log.notes!.isNotEmpty
                                ? Text(log.notes!)
                                : null,
                            trailing: Icon(
                              log.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: log.isCompleted
                                  ? Colors.green
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            onTap: () => _toggleHabitForDay(habit.id, selectedDay),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<HabitLog> _getEventsForDay(DateTime day) {
    return _getScheduledHabitsForDay(day);
  }

  List<HabitLog> _getScheduledHabitsForDay(DateTime day) {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    List<HabitLog> dayEvents = [];
    
    for (final habit in habits) {
      // Check if habit is scheduled for this day
      if (_isHabitScheduledForDay(habit, day)) {
        // Check if there's already a log for this day
        final existingLogs = _habitLogs[habit.id] ?? [];
        final existingLog = existingLogs.cast<HabitLog?>().firstWhere(
          (log) => log != null && 
            log.date.isAfter(dayStart.subtract(const Duration(microseconds: 1))) &&
            log.date.isBefore(dayEnd),
          orElse: () => null,
        );
        
        if (existingLog != null) {
          // Use the actual log
          dayEvents.add(existingLog);
        } else {
          // Create a placeholder for scheduled but not completed habit
          dayEvents.add(HabitLog(
            habitId: habit.id,
            date: dayStart,
            isCompleted: false,
            notes: null,
          ));
        }
      }
    }
    
    // Filter by selected habit if any
    if (_selectedHabitId != null) {
      dayEvents = dayEvents.where((log) => log.habitId == _selectedHabitId).toList();
    }
    
    return dayEvents;
  }

  bool _isHabitScheduledForDay(Habit habit, DateTime day) {
    // Only show habits for today and future dates, or past dates with actual logs
    final today = DateTime.now();
    final dayStart = DateTime(day.year, day.month, day.day);
    final todayStart = DateTime(today.year, today.month, today.day);
    
    // For past dates, only show if there's an actual log
    if (dayStart.isBefore(todayStart)) {
      final existingLogs = _habitLogs[habit.id] ?? [];
      return existingLogs.any((log) => 
          log.date.year == day.year && 
          log.date.month == day.month && 
          log.date.day == day.day);
    }
    
    // For current and future dates, check habit schedule
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
      case HabitFrequency.custom:
        return habit.weekdays.contains(day.weekday);
      default:
        return false;
    }
  }

  List<HabitLog> _getLogsForDay(DateTime day) {
    return _getScheduledHabitsForDay(day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay.value, selectedDay)) {
      setState(() {
        _selectedDay.value = selectedDay;
        _focusedDay.value = focusedDay;
      });
    }
  }

  Future<void> _toggleHabitForDay(String habitId, DateTime day) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final isCompleted = await habitProvider.toggleHabitCompletion(habitId, day);
    await _loadHabitLogs(); // Refresh logs
    
    if (mounted && isCompleted != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted 
                ? 'Habit completed! 🎉'
                : 'Habit unmarked 💪',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: isCompleted 
              ? Colors.green.withOpacity(0.8)
              : Colors.orange.withOpacity(0.8),
        ),
      );
    }
  }
}


