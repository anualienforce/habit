import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../widgets/stats_card.dart';
import '../services/admob_service.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<HabitLog> _habitLogs = [];
  Map<String, dynamic> _habitStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final today = DateTime.now();
    _selectedDay = today;
    _focusedDay = today;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    
    final logs = await habitProvider.getHabitLogs(
      widget.habitId,
      startDate: DateTime.now().subtract(const Duration(days: 365)),
      endDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    final stats = await habitProvider.getHabitStats(widget.habitId);
    
    setState(() {
      _habitLogs = logs;
      _habitStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        final habit = habitProvider.habits.firstWhere(
          (h) => h.id == widget.habitId,
          orElse: () => throw Exception('Habit not found'),
        );
        final category = habitProvider.getCategoryById(habit.categoryId);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _navigateToEdit(context, habit),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Habit', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteConfirmation(context, habit);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Habit Info Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: category?.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            (category != null)
                                ? (kCategoryIconConstants[category.id] ??
                                kCategoryIconConstants[category.id] ?? Icons.task_alt)
                                : Icons.task_alt,
                            color: category?.color,
                            size: 32,
                          ),

                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (habit.description != null && habit.description!.isNotEmpty)
                                Text(
                                  habit.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: category?.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      category?.name ?? 'No Category',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: category?.color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getFrequencyText(habit),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Tab Bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Statistics'),
                  Tab(icon: Icon(Icons.timeline), text: 'Progress'),
                ],
              ),
              
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCalendarTab(),
                    _buildStatisticsTab(),
                    _buildProgressTab(),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _toggleTodayCompletion(context, habit),
            child: FutureBuilder<bool>(
              future: _isCompletedToday(),
              builder: (context, snapshot) {
                final isCompleted = snapshot.data ?? false;
                return Icon(
                  isCompleted ? Icons.check : Icons.add,
                  color: Colors.white,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: TableCalendar<HabitLog>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Selected day info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_selectedDay),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<HabitLog?>(
                    future: _getLogForDay(_selectedDay),
                    builder: (context, snapshot) {
                      final log = snapshot.data;
                      if (log == null) {
                        return const Text('No entry for this day');
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                log.isCompleted ? Icons.check_circle : Icons.cancel,
                                color: log.isCompleted ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                log.isCompleted ? 'Completed' : 'Not completed',
                                style: TextStyle(
                                  color: log.isCompleted ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (log.notes != null && log.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Notes: ${log.notes}'),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_habitStats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Current Streak',
                  value: '${_habitStats['currentStreak']} days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Total Done',
                  value: _habitStats['totalCompletions'].toString(),
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
                  value: '${(_habitStats['completionRate30Days'] * 100).toStringAsFixed(0)}%',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: '7-Day Rate',
                  value: '${(_habitStats['completionRate7Days'] * 100).toStringAsFixed(0)}%',
                  icon: Icons.show_chart,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 7,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return Text(
                                  weekdays[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _generateWeeklyData(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _habitLogs.take(5).length,
                    itemBuilder: (context, index) {
                      final log = _habitLogs[index];
                      return ListTile(
                        leading: Icon(
                          log.isCompleted ? Icons.check_circle : Icons.cancel,
                          color: log.isCompleted ? Colors.green : Colors.red,
                        ),
                        title: Text(DateFormat('MMM d, y').format(log.date)),
                        subtitle: log.notes != null && log.notes!.isNotEmpty
                            ? Text(log.notes!)
                            : null,
                        trailing: Text(
                          log.isCompleted ? 'Completed' : 'Missed',
                          style: TextStyle(
                            color: log.isCompleted ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<HabitLog> _getEventsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    
    return _habitLogs.where((log) =>
        log.date.isAfter(dayStart.subtract(const Duration(microseconds: 1))) &&
        log.date.isBefore(dayEnd)).toList();
  }

  Future<HabitLog?> _getLogForDay(DateTime day) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    return await habitProvider.getHabitLogs(widget.habitId).then((logs) {
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      try {
        return logs.firstWhere((log) =>
            log.date.isAfter(dayStart.subtract(const Duration(microseconds: 1))) &&
            log.date.isBefore(dayEnd));
      } catch (e) {
        return null;
      }
    });
  }

  Future<bool> _isCompletedToday() async {
    final log = await _getLogForDay(DateTime.now());
    return log?.isCompleted ?? false;
  }

  List<BarChartGroupData> _generateWeeklyData() {
    // Generate sample weekly data
    return List.generate(7, (index) {
      final completions = (index % 3) + 1; // Sample data
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: completions.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  String _getFrequencyText(Habit habit) {
    switch (habit.frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        if (habit.weekdays.length == 7) {
          return 'Daily';
        } else {
          return '${habit.weekdays.length} days/week';
        }
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  void _navigateToEdit(BuildContext context, Habit habit) {
    // Show interstitial ad before navigating
    AdMobService().showInterstitialAd();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditHabitScreen(habit: habit),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
              
              final habitProvider = Provider.of<HabitProvider>(context, listen: false);
              await habitProvider.deleteHabit(habit.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Habit "${habit.name}" deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTodayCompletion(BuildContext context, Habit habit) async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final isCompleted = await habitProvider.toggleHabitCompletion(habit.id, DateTime.now());
    await _loadData(); // Refresh data
    
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
}


