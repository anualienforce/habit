import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import 'categories_screen.dart';
import 'premium_screen.dart';
import '../utils/theme_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  _GlassPill(
                    child: Text(
                      'Settings',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0E1D2F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle(theme, 'Appearance'),
              _sectionCard(
                isDark: isDark,
                child: Column(
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('Theme'),
                          subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showThemeDialog(context, themeProvider),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Data & Categories'),
              _sectionCard(
                isDark: isDark,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: const Text('Manage Categories'),
                      subtitle: const Text('Add, edit, or delete habit categories'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _navigateToCategories(context),
                    ),

                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Notifications'),
              _sectionCard(
                isDark: isDark,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Receive reminders for your habits'),
                      value: _notificationsEnabled ?? true,
                      onChanged: (value) async {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        await _setNotificationSetting(value);
                        if (value) {
                          final notificationService = NotificationService();
                          final granted = await notificationService
                              .requestPermissions()
                              .timeout(const Duration(seconds: 2), onTimeout: () => false);
                          if (!granted) {
                            if (mounted) {
                              setState(() {
                                _notificationsEnabled = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enable notifications in system settings'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                            return;
                          }
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    FutureBuilder<TimeOfDay>(
                      future: _getDefaultReminderTime(),
                      builder: (context, snapshot) {
                        final defaultTime = snapshot.data ?? const TimeOfDay(hour: 9, minute: 0);
                        return ListTile(
                          leading: const Icon(Icons.schedule_outlined),
                          title: const Text('Default Reminder Time'),
                          subtitle: Text(defaultTime.format(context)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showTimePickerDialog(context),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
          
          const SizedBox(height: 24),
          _sectionTitle(theme, 'Premium'),
          _sectionCard(
            isDark: isDark,
            child: ListenableBuilder(
              listenable: PurchaseService(),
              builder: (context, _) {
                final isPremium = PurchaseService().isPremium;
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.block_flipped),
                      title: const Text('Remove Ads'),
                      subtitle: Text(
                        isPremium ? 'Ads removed — Pro active' : 'View plans to remove ads',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _presentPaywallOrCustomerCenter(context, isPremium),
                    ),
                    if (isPremium) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.manage_accounts),
                        title: const Text('Manage subscription'),
                        subtitle: const Text('Cancel, restore, or change plan'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _presentCustomerCenter(context),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Support & Information Section
          Text(
            'Support & Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _sectionCard(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & FAQ'),
                  subtitle: const Text('Get help with using the app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showHelpDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Rate App'),
                  subtitle: const Text('Rate us on the app store'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRateDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('Version 1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          

        ],
      ),
    ),
  ),
);
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF0E1D2F),
      ),
    );
  }

  Card _sectionCard({required bool isDark, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isDark
            ? BorderSide(color: Colors.white.withOpacity(0.12), width: 0.5)
            : BorderSide.none,
      ),
      color: isDark ? const Color(0xE60F172A) : null,
      child: child,
    );
  }

  Future<void> _presentPaywallOrCustomerCenter(BuildContext context, bool isPremium) async {
    if (isPremium) {
      _presentRestoreOrManage(context);
      return;
    }
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const PremiumScreen(),
        ),
      );
    }
  }

  Future<void> _presentCustomerCenter(BuildContext context) async {
    _presentRestoreOrManage(context);
  }

  Future<void> _presentRestoreOrManage(BuildContext context) async {
    final success = await PurchaseService().restorePurchases();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Restore completed. Manage subscription in App Store.'
                : 'Restore failed. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // Settings persistence methods
  Future<bool> _getNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> _setNotificationSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<TimeOfDay> _getDefaultReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('default_reminder_hour') ?? 9;
    final minute = prefs.getInt('default_reminder_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _setDefaultReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_reminder_hour', time.hour);
    await prefs.setInt('default_reminder_minute', time.minute);
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await _getNotificationSetting();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System default'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Light'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark'),
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const CategoriesScreen(),
      ),
    );
  }

  Future<void> _showTimePickerDialog(BuildContext context) async {
    final current = await _getDefaultReminderTime();
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      await _setDefaultReminderTime(picked);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Default reminder time set to ${picked.format(context)}')),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Text(
            '• Add habits and assign them to categories.\n'
            '• Tap a habit to log it for today.\n'
            '• Enable notifications for reminders.\n'
            '• Use Premium to remove ads and unlock features.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate App'),
        content: const Text(
          'Enjoying the app? Your rating helps us improve and reach more users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app: launch store URL
            },
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Text(
          'Habit Tracker\nVersion 1.0.0\n\nA simple app to build better habits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
