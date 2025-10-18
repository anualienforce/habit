import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import 'premium_upgrade_screen.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          Text(
            'Appearance',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
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
          
          // Data & Categories Section
          Text(
            'Data & Categories',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
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
          
          // Notifications Section
          Text(
            'Notifications',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                FutureBuilder<bool>(
                  future: _getNotificationSetting(),
                  builder: (context, snapshot) {
                    final isEnabled = snapshot.data ?? true;
                    return SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Receive reminders for your habits'),
                      value: isEnabled,
                      onChanged: (value) async {
                        await _setNotificationSetting(value);
                        if (value) {
                          final notificationService = NotificationService();
                          final granted = await notificationService.requestPermissions();
                          if (!granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enable notifications in system settings'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                          ),
                        );
                      },
                    );
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
                ),/*
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Test Notifications'),
                  subtitle: const Text('Send a test notification to verify setup'),
                  trailing: const Icon(Icons.send),
                  onTap: () => _testNotifications(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Debug Notifications'),
                  subtitle: const Text('Show detailed notification debug info'),
                  trailing: const Icon(Icons.info),
                  onTap: () => _debugNotifications(context),
                ),*/
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Premium Section
          Text(
            'Premium',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                FutureBuilder<bool>(
                  future: PurchaseService().checkPremiumStatus(),
                  builder: (context, snapshot) {
                    final isPremium = snapshot.data ?? false;

                    if (isPremium) {
                      return ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: const Text('Premium Active'),
                        subtitle: const Text('Thank you for your support! 🎉'),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumUpgradeScreen(),
                          ),
                        ),
                      );
                    } else {
                      return ListTile(
                        leading: const Icon(Icons.star_border),
                        title: const Text('Upgrade to Premium'),
                        subtitle: const Text('Remove ads and unlock premium features'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumUpgradeScreen(),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
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
          Card(
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
    );
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CategoriesScreen(),
      ),
    );
  }



  void _showTimePickerDialog(BuildContext context) async {
    final currentTime = await _getDefaultReminderTime();
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (time != null) {
      await _setDefaultReminderTime(time);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Default reminder time set to ${time.format(context)}'),
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Text(
            'Welcome to Habit Tracker!\n\n'
            '• Tap the + button to create a new habit\n'
            '• Swipe left on a habit to delete it\n'
            '• Swipe right on a habit to edit it\n'
            '• Tap the circle to mark a habit as complete\n'
            '• Use the Calendar tab to see your progress over time\n'
            '• Check the Statistics tab for detailed analytics\n\n'
            'For more help, contact support at support@habittracker.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Our App'),
        content: const Text('If you enjoy using Habit Tracker, please consider rating us on the app store!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                ),
              );
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Habit Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.today, size: 48),
      children: [
        const Text(
          'A comprehensive habit tracking app built with Flutter. '
          'Track your daily habits, view your progress, and build consistency in your life.',
        ),
      ],
    );
  }

  void _testNotifications(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testing notifications...'),
            ],
          ),
        ),
      );

      final notificationService = NotificationService();
      
      // First check status
      final status = await notificationService.getNotificationStatus();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show status dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    status['initialized'] ? Icons.check_circle : Icons.error,
                    color: status['initialized'] ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text('Service Initialized: ${status['initialized']}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    status['permissions'] ? Icons.check_circle : Icons.error,
                    color: status['permissions'] ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text('Permissions Granted: ${status['permissions']}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    status['exactAlarms'] ? Icons.check_circle : Icons.warning,
                    color: status['exactAlarms'] ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text('Exact Alarms: ${status['exactAlarms']}'),
                ],
              ),
              const SizedBox(height: 16),
              if (status['initialized'] && status['permissions'])
                const Text('✅ Notifications should work! Check for the test notification.')
              else
                const Text('❌ Issues found. Please check permissions in device settings.'),
            ],
          ),
          actions: [
            if (status['initialized'] && status['permissions'])
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await notificationService.testNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent! Check your notification panel.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                child: const Text('Send Test'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _debugNotifications(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Gathering debug info...'),
            ],
          ),
        ),
      );

      final notificationService = NotificationService();
      
      // Print debug info to console
      await notificationService.printDebugInfo();
      
      // Get debug info for display
      final debugInfo = await notificationService.getDebugInfo();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show debug dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Initialized: ${debugInfo['service_initialized']}'),
                Text('Timestamp: ${debugInfo['timestamp']}'),
                
                if (debugInfo.containsKey('notification_status')) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Permissions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Notifications: ${debugInfo['notification_status']['permissions']}'),
                  Text('Exact Alarms: ${debugInfo['notification_status']['exactAlarms']}'),
                ],
                
                if (debugInfo.containsKey('pending_notifications')) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Pending Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Count: ${debugInfo['pending_notifications']['count']}'),
                ],
                
                if (debugInfo.containsKey('platform')) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Platform',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Android: ${debugInfo['platform']['is_android']}'),
                  Text('iOS: ${debugInfo['platform']['is_ios']}'),
                ],
                
                const SizedBox(height: 16),
                const Text(
                  'Note: Detailed debug info has been printed to console.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting debug info: $e'),
          backgroundColor: Colors.red,
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
}
