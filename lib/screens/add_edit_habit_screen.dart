import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit;

  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategoryId;
  HabitFrequency _selectedFrequency = HabitFrequency.daily;
  List<int> _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
  int _targetPerWeek = 7;
  int _targetPerMonth = 30;
  TimeOfDay? _reminderTime;
  bool _isReminderEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.habit != null) {
      _initializeWithHabit();
    }
  }

  void _initializeWithHabit() {
    final habit = widget.habit!;
    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _selectedCategoryId = habit.categoryId;
    _selectedFrequency = habit.frequency;
    _selectedWeekdays = List.from(habit.weekdays);
    _targetPerWeek = habit.targetPerWeek;
    _targetPerMonth = habit.targetPerMonth;
    _isReminderEnabled = habit.isReminderEnabled;
    if (habit.reminderTime != null) {
      _reminderTime = TimeOfDay.fromDateTime(habit.reminderTime!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitProvider = Provider.of<HabitProvider>(context);
    final isEditing = widget.habit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Habit' : 'Add Habit'),
        actions: [
          TextButton(
            onPressed: _canSave() ? _saveHabit : null,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Habit Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g., Drink 8 glasses of water',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add more details about this habit',
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Category Selection
            Text(
              'Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: habitProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = habitProvider.categories[index];
                  final isSelected = category.id == _selectedCategoryId;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = category.id;
                        });
                      },
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color.withOpacity(0.2)
                              : theme.colorScheme.surface,
                          border: Border.all(
                            color: isSelected
                                ? category.color
                                : theme.colorScheme.outline.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              kCategoryIconConstants[category.id] ??
                                  kCategoryIconConstants[category.id] ?? Icons.task_alt,
                              color: category.color,
                              size: 32,
                            ),

                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Frequency Selection
            Text(
              'Frequency',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<HabitFrequency>(
              segments: const [
                ButtonSegment(
                  value: HabitFrequency.daily,
                  label: Text('Daily'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment(
                  value: HabitFrequency.weekly,
                  label: Text('Weekly'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment(
                  value: HabitFrequency.custom,
                  label: Text('Custom'),
                  icon: Icon(Icons.tune),
                ),
              ],
              selected: {_selectedFrequency},
              onSelectionChanged: (Set<HabitFrequency> selection) {
                setState(() {
                  _selectedFrequency = selection.first;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Weekday Selection (for weekly and custom)
            if (_selectedFrequency != HabitFrequency.daily) ...[
              Text(
                'Select Days',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 1; i <= 7; i++)
                    FilterChip(
                      label: Text(_getWeekdayShort(i)),
                      selected: _selectedWeekdays.contains(i),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeekdays.add(i);
                          } else {
                            _selectedWeekdays.remove(i);
                          }
                          _selectedWeekdays.sort();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Target Settings (for custom frequency)
            if (_selectedFrequency == HabitFrequency.custom) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _targetPerWeek.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Times per week',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _targetPerWeek = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _targetPerMonth.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Times per month',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _targetPerMonth = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            
            // Reminder Settings
            Text(
              'Reminders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable Reminders'),
              subtitle: const Text('Get notified to complete your habit'),
              value: _isReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _isReminderEnabled = value;
                });
              },
            ),
            
            if (_isReminderEnabled) ...[
              ListTile(
                title: const Text('Reminder Time'),
                subtitle: Text(_reminderTime?.format(context) ?? 'Not set'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectReminderTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canSave() {
    return _nameController.text.trim().isNotEmpty &&
        _selectedCategoryId != null &&
        !_isSaving;
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate() || !_canSave()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      print('🔄 Starting habit save process...');
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      
      DateTime? reminderDateTime;
      if (_isReminderEnabled && _reminderTime != null) {
        final now = DateTime.now();
        reminderDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          _reminderTime!.hour,
          _reminderTime!.minute,
        );
      }

      final habit = Habit(
        id: widget.habit?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        categoryId: _selectedCategoryId!,
        frequency: _selectedFrequency,
        weekdays: _selectedWeekdays,
        targetPerWeek: _targetPerWeek,
        targetPerMonth: _targetPerMonth,
        reminderTime: reminderDateTime,
        isReminderEnabled: _isReminderEnabled,
        createdAt: widget.habit?.createdAt,
      );

      if (widget.habit != null) {
        print('📝 Updating existing habit: ${habit.name}');
        await habitProvider.updateHabit(habit);
        print('✅ Habit updated successfully in provider');
      } else {
        print('➕ Adding new habit: ${habit.name}');
        await habitProvider.addHabit(habit);
        print('✅ Habit added successfully in provider');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.habit != null
                  ? 'Habit updated successfully!'
                  : 'Habit created successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving habit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      print('🏁 Finished habit save process');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getWeekdayShort(int weekday) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return weekdays[weekday - 1];
  }
}


