import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'utils/theme_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  bool _servicesKickedOff = false;

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

    // Kick off theme + data in background; avoid blocking first frame.
    final themeFuture = themeProvider.initialize();
    final habitFuture = habitProvider.initialize();

    // Permissions check in background.
    final permissionsFuture = _loadPermissionsFlag();

    // Kick off non-blocking service init that can take longer (ads, notifications, purchases).
    if (!_servicesKickedOff) {
      _servicesKickedOff = true;
      _initializeBackgroundServices(notificationService, purchaseService);
    }

    // Hold splash for 1s to show transition, then reveal UI.
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }

    // Best-effort; ignore failures so startup isn't blocked.
    themeFuture.catchError((_) {});
    habitFuture.catchError((_) {});
    permissionsFuture.catchError((_) {});
  }

  Future<void> _loadPermissionsFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsRequested = prefs.getBool('permissions_requested') ?? false;
      if (mounted) {
        setState(() {
          _showPermissionScreen = !permissionsRequested;
        });
      }
    } catch (_) {
      // If prefs fail, just proceed without blocking startup.
    }
  }

  Future<void> _initializeBackgroundServices(
    NotificationService notificationService,
    PurchaseService purchaseService,
  ) async {
    // Skip heavy native services on web.
    if (kIsWeb) return;

    // Initialize notifications (needed before permission screen requests).
    await notificationService.initialize();

    // Initialize ads only on Android.
    if (Platform.isAndroid) {
      await AdMobService.initialize();
      AdMobService().loadInterstitialAd();
    }

    // Purchases can be slower—do not block the first frame.
    await purchaseService.initialize();
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
        // If still initializing, render a gradient background so splash transitions smoothly.
        if (!_isInitialized || habitProvider.isLoading) {
          final brightness = MediaQuery.of(context).platformBrightness;
          final bg = AppGradients.background(brightness);
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bg,
                ),
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
