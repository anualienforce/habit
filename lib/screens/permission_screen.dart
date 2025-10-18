import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionScreen({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  Map<String, bool> _permissionStatus = {
    'notifications': false,
    'exactAlarms': false,
  };

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await _notificationService.getNotificationStatus();
      setState(() {
        _permissionStatus['notifications'] = status['permissions'] ?? false;
        _permissionStatus['exactAlarms'] = status['exactAlarms'] ?? false;
      });
    } catch (e) {
      print('Error checking permissions: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Initialize notification service
      await _notificationService.initialize();
      
      // Request permissions
      final granted = await _notificationService.requestPermissions();
      
      if (granted) {
        // Mark permissions as requested
        await _markPermissionsRequested();
        
        // Check final status
        await _checkCurrentPermissions();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Permissions granted! You can now receive habit reminders.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Close permission screen
        widget.onPermissionsGranted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Some permissions were denied. You can enable them later in Settings.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error requesting permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _markPermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_requested', true);
  }

  void _skipPermissions() async {
    await _markPermissionsRequested();
    widget.onPermissionsGranted();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Header
              Icon(
                Icons.notifications_active,
                size: 80,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Enable Notifications',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Get reminded to complete your habits and stay on track with your goals!',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Permission cards
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          _buildPermissionCard(
                            icon: Icons.notifications,
                            title: 'Notification Permission',
                            description: 'Allows the app to send you habit reminders',
                            isGranted: _permissionStatus['notifications']!,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionCard(
                            icon: Icons.schedule,
                            title: 'Exact Timing',
                            description: 'Ensures reminders arrive exactly on time',
                            isGranted: _permissionStatus['exactAlarms']!,
                            isRequired: false,
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionCard(
                            icon: Icons.power_settings_new,
                            title: 'Background Activity',
                            description: 'Keeps reminders working when device restarts',
                            isGranted: true, // Always granted via manifest
                            isRequired: true,
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Why we need these permissions
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Why These Permissions?',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '• Notifications help you build consistent habits\n'
                                    '• Exact timing ensures you get reminded at the right moment\n'
                                    '• Background activity keeps your habit streaks going\n'
                                    '• All data stays on your device - no tracking!',
                                    style: TextStyle(height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Grant Permissions',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _skipPermissions,
                      child: const Text('Skip for Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required bool isRequired,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isGranted ? Colors.green : (isRequired ? Colors.orange : Colors.grey),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(description),
        trailing: Icon(
          isGranted ? Icons.check_circle : Icons.circle_outlined,
          color: isGranted ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
