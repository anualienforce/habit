import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/category.dart';
import '../screens/habit_detail_screen.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final Category category;
  final int currentStreak;
  final bool isCompletedToday;
  final VoidCallback onToggleCompletion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.category,
    required this.currentStreak,
    required this.isCompletedToday,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: Key(habit.id),
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.edit,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          onEdit();
          return false; // Don't dismiss
        } else if (direction == DismissDirection.endToStart) {
          // Delete action
          onDelete();
          return false; // Don't dismiss (handled in delete callback)
        }
        return false;
      },
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HabitDetailScreen(habitId: habit.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon and color
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    kCategoryIconConstants[category.id] ??
                        kCategoryIconConstants[category.id] ?? Icons.task_alt,
                    color: category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Habit details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (habit.description != null && habit.description!.isNotEmpty)
                        Text(
                          habit.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _getScheduleText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Streak counter
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: currentStreak > 0
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: currentStreak > 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentStreak',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: currentStreak > 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Completion toggle
                GestureDetector(
                  onTap: onToggleCompletion,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompletedToday
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompletedToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: isCompletedToday
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getScheduleText() {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        if (habit.weekdays.length == 7) {
          return 'Daily';
        } else if (habit.weekdays.length == 1) {
          return _getWeekdayName(habit.weekdays.first);
        } else {
          return '${habit.weekdays.length} days a week';
        }
      case HabitFrequency.custom:
        if (habit.targetPerWeek > 0) {
          return '${habit.targetPerWeek}x per week';
        } else if (habit.targetPerMonth > 0) {
          return '${habit.targetPerMonth}x per month';
        } else {
          return 'Custom schedule';
        }
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return weekdays[weekday - 1];
  }
}


