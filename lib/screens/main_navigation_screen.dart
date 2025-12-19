import 'package:flutter/material.dart';
import '../utils/theme_tokens.dart';
import '../widgets/banner_ad_widget.dart';
import 'habits_screen.dart';
import 'calendar_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HabitsScreen(),
    const CalendarScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navGradient = AppGradients.bottomNav(theme.brightness);
    final accent = AppGradients.button(theme.brightness).first;
    final bgColor = isDark
        ? navGradient.last.withOpacity(0.9)
        : navGradient.last.withOpacity(0.92);

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
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
            const BannerAdWidget(showOnlyWhenLoaded: true),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: bgColor,
        elevation: 8,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: accent,
        unselectedItemColor:
            (isDark ? Colors.white : const Color(0xFF0E1D2F)).withOpacity(0.65),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_rounded),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
