import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/habit_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'services/purchase_service.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/permission_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AdMob only on Android

    await AdMobService.initialize();

  
  // Initialize and request permissions for notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  bool hasPermission = await notificationService.requestPermissions();
  debugPrint('Notification permission granted: $hasPermission');
  
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Habit Tracker',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _showPermissionScreen = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final notificationService = NotificationService();
    final purchaseService = PurchaseService();
    
    await Future.wait([
      themeProvider.initialize(),
      habitProvider.initialize(),
      notificationService.initialize(),
      purchaseService.initialize(),
    ]);
    
    // Check if permissions have been requested
    final prefs = await SharedPreferences.getInstance();
    final permissionsRequested = prefs.getBool('permissions_requested') ?? false;
    
    setState(() {
      _showPermissionScreen = !permissionsRequested;
      _isInitialized = true;
    });
    
    // Load the first interstitial ad (Android only)
      AdMobService().loadInterstitialAd();

  }

  void _onPermissionsGranted() {
    setState(() {
      _showPermissionScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Show loading screen while initializing
        if (!_isInitialized || habitProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your habits...'),
                ],
              ),
            ),
          );
        }
        
        // Show error screen if there's an error
        if (habitProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${habitProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => habitProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Show permission screen if permissions haven't been requested
        if (_showPermissionScreen) {
          return PermissionScreen(
            onPermissionsGranted: _onPermissionsGranted,
          );
        }
        
        // Show main app
        return const MainNavigationScreen();
      },
    );
  }
}
