import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';
import '../providers/habit_provider.dart';
import '../widgets/stats_card.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
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
          if (habitProvider.habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Statistics Yet',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create some habits to see your progress!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selection
                Card(
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
                
                // Overall Statistics
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
                
                // Individual Habit Statistics
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
          );
        },
      ),
    );
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
                    value: '${(stats['avgCompletion'] * 100).toStringAsFixed(0)}%',
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
                    value: '${stats['bestStreak']} days',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Total Completions',
                    value: stats['totalCompletions'].toString(),
                    icon: Icons.check_circle,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCompletionChart(stats['chartData']),
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
                    value: '${stats['currentStreak']} days',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Total Done',
                    value: stats['totalCompletions'].toString(),
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
                    value: '${(stats['completionRate30Days'] * 100).toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: '7-Day Rate',
                    value: '${(stats['completionRate7Days'] * 100).toStringAsFixed(0)}%',
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
      totalCompletions += stats['totalCompletions'] as int;
      bestStreak = [bestStreak, stats['currentStreak'] as int].reduce((a, b) => a > b ? a : b);
      totalCompletionRate += stats['completionRate30Days'] as double;
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


