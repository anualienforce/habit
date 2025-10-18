import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../services/admob_service.dart';
import 'add_edit_habit_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedCategoryFilter = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) {
              final habitProvider = Provider.of<HabitProvider>(context, listen: false);
              final categories = habitProvider.categories;
              
              return [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('All Categories'),
                ),
                ...categories.map((category) => PopupMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        kCategoryIconConstants[category.id] ??
                            kCategoryIconConstants[category.id] ?? Icons.task_alt,
                        color: category.color,
                        size: 20,
                      ),

                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                )),
              ];
            },
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final habitsWithDetails = _selectedCategoryFilter == null
              ? habitProvider.habitsWithDetails
              : habitProvider.habitsWithDetails
                  .where((habitDetail) => 
                      habitDetail['habit'].categoryId == _selectedCategoryFilter)
                  .toList();

          if (habitsWithDetails.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.today_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedCategoryFilter == null
                        ? 'No habits yet'
                        : 'No habits in this category',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedCategoryFilter == null
                        ? 'Create your first habit to get started!'
                        : 'Create a habit in this category or remove the filter.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_selectedCategoryFilter == null)
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddHabit(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Habit'),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => habitProvider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habitsWithDetails.length,
              itemBuilder: (context, index) {
                final habitDetail = habitsWithDetails[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HabitCard(
                    habit: habitDetail['habit'],
                    category: habitDetail['category'],
                    currentStreak: habitDetail['currentStreak'],
                    isCompletedToday: habitDetail['isCompletedToday'],
                    onToggleCompletion: () => _toggleHabitCompletion(
                      context,
                      habitDetail['habit'].id,
                    ),
                    onEdit: () => _navigateToEditHabit(context, habitDetail['habit']),
                    onDelete: () => _deleteHabit(context, habitDetail['habit']),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddHabit(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddHabit(BuildContext context) {
    // Show interstitial ad before navigating
    AdMobService().showInterstitialAd();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditHabitScreen(),
      ),
    );
  }

  void _navigateToEditHabit(BuildContext context, dynamic habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditHabitScreen(habit: habit),
      ),
    );
  }

  Future<void> _toggleHabitCompletion(BuildContext context, String habitId) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final isCompleted = await habitProvider.toggleHabitCompletion(habitId, DateTime.now());
    
    // Show appropriate feedback based on completion status
    if (context.mounted && isCompleted != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted 
                ? 'Great job! Keep it up! 🎉'
                : 'Habit unmarked. Try again tomorrow! 💪',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: isCompleted 
              ? Colors.green.withOpacity(0.8)
              : Colors.orange.withOpacity(0.8),
        ),
      );
    }
  }

  Future<void> _deleteHabit(BuildContext context, dynamic habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      
      // Store habit data for undo functionality
      final deletedHabit = habit;
      final deletedHabitLogs = await habitProvider.getHabitLogs(habit.id);
      
      await habitProvider.deleteHabit(habit.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${habit.name}" deleted'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Restore the habit
                await habitProvider.addHabit(deletedHabit);
                
                // Restore the logs
                for (final log in deletedHabitLogs) {
                  await habitProvider.addHabitLog(log);
                }
                
                await habitProvider.loadHabits();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${deletedHabit.name}" restored'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }
}


