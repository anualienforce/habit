import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import 'premium_upgrade_screen.dart';
import 'categories_screen.dart';
import '../utils/theme_tokens.dart';

enum _RemoveAdsPlan { monthly, yearly, lifetime }

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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.block_flipped),
                  title: const Text('Remove Ads'),
                  subtitle: const Text('View plans to remove ads'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRemoveAdsPopup(context),
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

  Future<Map<String, dynamic>> _loadPlanData() async {
    final purchaseService = PurchaseService();
    await purchaseService.initialize();
    final isPremium = await purchaseService.checkPremiumStatus();
    return {
      'isPremium': isPremium,
      'monthly': purchaseService.getMonthlyPrice(),
      'yearly': purchaseService.getYearlyPrice(),
      'lifetime': purchaseService.getRemoveAdsLifetimePrice(),
    };
  }

  void _showRemoveAdsPopup(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _loadPlanData(),
              builder: (context, snapshot) {
                final data = snapshot.data;
                final isPremium = data?['isPremium'] as bool? ?? false;
                final monthly = data?['monthly'] as String? ?? '\$3.00/month';
                final yearly = data?['yearly'] as String? ?? '\$19.00/year';
                final lifetime = data?['lifetime'] as String? ?? '\$49.00 lifetime';

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: isDark ? const Color(0xF0162338) : Colors.white.withOpacity(0.94),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF374151).withOpacity(0.7)
                          : const Color(0xFF94A3B8).withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.6 : 0.25),
                        blurRadius: isDark ? 30 : 18,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Remove Ads Plans',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF111827).withOpacity(0.8)
                                    : const Color(0xFFE2E8F0).withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF475569).withOpacity(0.7)
                                      : const Color(0xFF94A3B8).withOpacity(0.5),
                                ),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: isDark
                              ? const Color(0xFF111827).withOpacity(0.9)
                              : const Color(0xFFEFF6FF).withOpacity(0.9),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF818CF8).withOpacity(0.6)
                                : const Color(0xFF818CF8).withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Choose a plan to remove ads',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isPremium)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildStatusChip(
                            context,
                            label: 'Ads removed',
                            color: Colors.green,
                            icon: Icons.verified,
                          ),
                        ),
                      _planRow(
                        context,
                        isDark: isDark,
                        title: 'Monthly',
                        description: 'Ad-free for 1 month (auto-renewing).',
                        price: monthly,
                        icon: Icons.calendar_today_rounded,
                        onTap: () => _purchasePlan(context, _RemoveAdsPlan.monthly),
                        isDisabled: isPremium,
                      ),
                      _planRow(
                        context,
                        isDark: isDark,
                        title: 'Yearly',
                        description: 'Ad-free for 12 months (auto-renewing).',
                        price: yearly,
                        icon: Icons.calendar_view_month,
                        onTap: () => _purchasePlan(context, _RemoveAdsPlan.yearly),
                        isDisabled: isPremium,
                      ),
                      _planRow(
                        context,
                        isDark: isDark,
                        title: 'Lifetime',
                        description: 'Pay once, ads removed forever.',
                        price: lifetime,
                        icon: Icons.all_inclusive,
                        onTap: () => _purchasePlan(context, _RemoveAdsPlan.lifetime),
                        isDisabled: isPremium,
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        color: isDark
                            ? const Color(0xFF374151).withOpacity(0.9)
                            : const Color(0xFFE2E8F0).withOpacity(0.9),
                        height: 16,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.refresh,
                          color: isDark ? const Color(0xFFE5E7EB) : theme.colorScheme.primary,
                        ),
                        title: Text(
                          'Restore Purchases',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          'Re-activate purchases after reinstall or device change.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569),
                          ),
                        ),
                        onTap: () async {
                          await _restorePurchases(context);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _planRow(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String description,
    required String price,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDisabled,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1F2937).withOpacity(0.8)
                    : const Color(0xFF818CF8).withOpacity(0.16),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFFA855F7)]
                      : const [Color(0xFF1D4ED8), Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                ),
              ),
              child: Text(
                price,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await _getNotificationSetting();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.info_outline),
          title: Text('Habit Tracker'),
          content: Text('A comprehensive habit tracking app built with Flutter. Track '
              'your daily habits, view your progress, and build consistency in your life.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
    },
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

  Widget _buildStatusChip(BuildContext context,
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDisabled,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: Text(price),
      ),
    );
  }

  Future<void> _purchasePlan(BuildContext context, _RemoveAdsPlan plan) async {
    if (!Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remove Ads plans are available on iOS.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final purchaseService = PurchaseService();
    await purchaseService.initialize();

    bool success = false;
    switch (plan) {
      case _RemoveAdsPlan.monthly:
        success = await purchaseService.purchaseSubscription(isYearly: false);
        break;
      case _RemoveAdsPlan.yearly:
        success = await purchaseService.purchaseSubscription(isYearly: true);
        break;
      case _RemoveAdsPlan.lifetime:
        success = await purchaseService.purchaseRemoveAds();
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Purchase initiated. Complete it in the App Store sheet.'
              : 'Purchase failed to start. Please try again.',
        ),
        backgroundColor: success ? Colors.blue : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _restorePurchases(BuildContext context) async {
    final purchaseService = PurchaseService();
    await purchaseService.initialize();

    final success = await purchaseService.restorePurchases();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Restore requested. If eligible, App Store will confirm.'
              : 'Restore failed. Please try again.',
        ),
        backgroundColor: success ? Colors.blue : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
