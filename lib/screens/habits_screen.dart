import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../services/admob_service.dart';
import 'add_edit_habit_screen.dart';
import '../utils/theme_tokens.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  String? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundGradient = AppGradients.background(theme.brightness);
    final buttonGradient = AppGradients.button(theme.brightness);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Consumer<HabitProvider>(
            builder: (context, habitProvider, child) {
              final habitsWithDetails = _selectedCategoryFilter == null
                  ? habitProvider.habitsWithDetails
                  : habitProvider.habitsWithDetails
                      .where((habitDetail) =>
                          habitDetail['habit'].categoryId == _selectedCategoryFilter)
                      .toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        _GlassPill(
                          child: Text(
                            'My Habits',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0E1D2F),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _GlassCircleIcon(
                          icon: Icons.filter_list,
                          onTap: () => _showFilterMenu(context),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surface,
                      onRefresh: () => habitProvider.refresh(),
                      child: habitsWithDetails.isEmpty
                          ? _EmptyState(
                              isDark: isDark,
                              buttonGradient: buttonGradient,
                              onAddHabit: () => _navigateToAddHabit(context),
                              hasFilter: _selectedCategoryFilter != null,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _GradientFab(
        gradientColors: buttonGradient,
        onTap: () => _navigateToAddHabit(context),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final categories = habitProvider.categories;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromLTRB(
      overlay.size.width - 120,
      kToolbarHeight + 20,
      16,
      0,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(
          value: 'all',
          child: Text('All Categories'),
        ),
        ...categories.map(
          (category) => PopupMenuItem(
            value: category.id,
            child: Row(
              children: [
                Icon(
                  kCategoryIconConstants[category.id] ??
                      kCategoryIconConstants[category.id] ??
                      Icons.task_alt,
                  color: category.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(category.name),
              ],
            ),
          ),
        ),
      ],
    );

    if (selected != null) {
      setState(() {
        _selectedCategoryFilter = selected == 'all' ? null : selected;
      });
    }
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

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final List<Color> buttonGradient;
  final VoidCallback onAddHabit;
  final bool hasFilter;

  const _EmptyState({
    required this.isDark,
    required this.buttonGradient,
    required this.onAddHabit,
    required this.hasFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : const Color(0xFF0E1D2F);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 40,
              color: isDark ? Colors.white : const Color(0xFF0E1D2F),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasFilter ? 'No habits in this category' : 'No habits yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Create a habit in this category or clear the filter.'
                : 'Create your first habit to get started!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withOpacity(0.72),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _GradientButton(
            label: 'Add Habit',
            gradientColors: buttonGradient,
            onTap: onAddHabit,
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientFab extends StatelessWidget {
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GradientFab({
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: gradientColors),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;

  const _GlassPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

class _GlassCircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _GlassCircleIcon({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withOpacity(0.14) : Colors.white,
          border: Border.all(color: Colors.white.withOpacity(isDark ? 0.25 : 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF0E1D2F),
        ),
      ),
    );
  }
}


