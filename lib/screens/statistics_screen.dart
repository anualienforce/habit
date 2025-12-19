import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';
import '../providers/habit_provider.dart';
import '../widgets/stats_card.dart';
import '../utils/theme_tokens.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? _selectedHabitId;
  int _selectedPeriod = 30; // days

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppGradients.background(theme.brightness),
          ),
        ),
        child: SafeArea(
          child: Consumer<HabitProvider>(
            builder: (context, habitProvider, child) {
              if (habitProvider.habits.isEmpty) {
                return _EmptyState(
                  title: 'No Statistics Yet',
                  subtitle: 'Create some habits to see your progress!',
                  isDark: isDark,
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        _GlassPill(
                          child: Text(
                            'Statistics',
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time Period',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SegmentedButton<int>(
                                    segments: const [
                                      ButtonSegment(value: 7, label: Text('7 Days')),
                                      ButtonSegment(value: 30, label: Text('30 Days')),
                                      ButtonSegment(value: 90, label: Text('90 Days')),
                                    ],
                                    selected: {_selectedPeriod},
                                    onSelectionChanged: (Set<int> selection) {
                                      setState(() {
                                        _selectedPeriod = selection.first;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedHabitId == null) ...[
                            Text(
                              'Overall Statistics',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildOverallStats(habitProvider),
                            const SizedBox(height: 24),
                          ],
                          if (_selectedHabitId != null) ...[
                            Text(
                              'Habit Statistics',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildHabitStats(habitProvider, _selectedHabitId!),
                          ] else ...[
                            Text(
                              'Habits Overview',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildHabitsOverview(habitProvider),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final habits = habitProvider.habits;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromLTRB(
      overlay.size.width - 140,
      kToolbarHeight + 20,
      16,
      0,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem(value: 'all', child: Text('All Habits')),
        ...habits.map(
          (habit) => PopupMenuItem(
            value: habit.id,
            child: Text(habit.name),
          ),
        ),
      ],
    );

    if (selected != null) {
      setState(() {
        _selectedHabitId = selected == 'all' ? null : selected;
      });
    }
  }

  Widget _buildOverallStats(HabitProvider habitProvider) {
    final habits = habitProvider.habits;
    final totalHabits = habits.length;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateOverallStats(habitProvider),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data!;
        final avgCompletion = (stats['avgCompletion'] ?? 0) as num;
        final bestStreak = (stats['bestStreak'] ?? 0) as num;
        final totalCompletions = (stats['totalCompletions'] ?? 0) as num;
        final chartData = stats['chartData'] as List<FlSpot>? ?? const <FlSpot>[];
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Total Habits',
                    value: totalHabits.toString(),
                    icon: Icons.list_rounded,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Avg Completion',
                    value: '${(avgCompletion * 100).toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Best Streak',
                    value: '${bestStreak} days',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Total Completions',
                    value: totalCompletions.toString(),
                    icon: Icons.check_circle,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCompletionChart(chartData),
          ],
        );
      },
    );
  }

  Widget _buildHabitStats(HabitProvider habitProvider, String habitId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: habitProvider.getHabitStats(habitId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = snapshot.data!;
        final habit = habitProvider.habits.firstWhere((h) => h.id == habitId);
        final category = habitProvider.getCategoryById(habit.categoryId);
        final currentStreak = (stats['currentStreak'] ?? 0) as num;
        final totalCompletions = (stats['totalCompletions'] ?? 0) as num;
        final rate30 = (stats['completionRate30Days'] ?? 0) as num;
        final rate7 = (stats['completionRate7Days'] ?? 0) as num;
        
        return Column(
          children: [
            // Habit Info
            Card(
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: category?.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    (category != null)
                        ? (kCategoryIconConstants[category.id] ??
                        kCategoryIconConstants[category.id] ?? Icons.task_alt)
                        : Icons.task_alt,
                    color: category?.color,
                  ),

                ),
                title: Text(habit.name),
                subtitle: Text(category?.name ?? 'No Category'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Current Streak',
                    value: '${currentStreak.toInt()} days',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Total Done',
                    value: totalCompletions.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: '30-Day Rate',
                    value: '${(rate30 * 100).toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: '7-Day Rate',
                    value: '${(rate7 * 100).toStringAsFixed(0)}%',
                    icon: Icons.show_chart,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitsOverview(HabitProvider habitProvider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habitProvider.habitsWithDetails.length,
      itemBuilder: (context, index) {
        final habitDetail = habitProvider.habitsWithDetails[index];
        final habit = habitDetail['habit'];
        final category = habitDetail['category'];
        final streak = habitDetail['currentStreak'];
        
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
                color: category?.color,
              ),
            ),
            title: Text(habit.name),
            subtitle: Text('${category?.name ?? 'No Category'} • $streak day streak'),
            trailing: IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                setState(() {
                  _selectedHabitId = habit.id;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionChart(List<FlSpot> chartData) {
    if (chartData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _calculateOverallStats(HabitProvider habitProvider) async {
    final habits = habitProvider.habits;
    int totalCompletions = 0;
    int bestStreak = 0;
    double totalCompletionRate = 0;
    List<FlSpot> chartData = [];

    for (int i = 0; i < habits.length; i++) {
      final habit = habits[i];
      final stats = await habitProvider.getHabitStats(habit.id);
      final habitTotal = (stats['totalCompletions'] ?? 0) as num;
      final habitStreak = (stats['currentStreak'] ?? 0) as num;
      final habitRate = (stats['completionRate30Days'] ?? 0) as num;
      totalCompletions += habitTotal.toInt();
      bestStreak = [bestStreak, habitStreak.toInt()].reduce((a, b) => a > b ? a : b);
      totalCompletionRate += habitRate.toDouble();
    }

    // Generate chart data (simplified - showing last 7 days)
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      double dayCompletionRate = 0.5 + (i * 0.1); // Mock data
      chartData.add(FlSpot(i.toDouble(), dayCompletionRate));
    }

    return {
      'totalCompletions': totalCompletions,
      'bestStreak': bestStreak,
      'avgCompletion': habits.isNotEmpty ? totalCompletionRate / habits.length : 0.0,
      'chartData': chartData,
    };
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : const Color(0xFF0E1D2F);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: textColor.withOpacity(0.7)),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
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


