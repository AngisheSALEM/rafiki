import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/tts_service.dart';
import 'services/stt_service.dart';
import 'services/raspberry_service.dart';
import 'services/token_service.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home_dashboard/screens/home_dashboard_screen.dart';
import 'features/voice_interaction/screens/rafiki_mouth_screen.dart';
import 'features/raspberry_connect/screens/pi_pairing_screen.dart';
import 'features/owner_dashboard/screens/owner_dashboard_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/history/screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TTSService()),
        ChangeNotifierProvider(create: (_) => STTService()),
        ChangeNotifierProvider(create: (_) => RaspberryPiService()),
      ],
      child: const RafikiApp(),
    ),
  );
}

class RafikiApp extends StatelessWidget {
  const RafikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rafiki Robot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  bool _hasCompletedOnboarding = false;
  bool _isLoggedIn = false;
  String _parentName = "Parent Rafiki";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final loggedIn = await TokenService.isLoggedIn();
    final name = await TokenService.getParentName();

    if (loggedIn) {
      setState(() {
        _isLoggedIn = true;
        if (name != null && name.isNotEmpty) {
          _parentName = name;
        }
      });
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCompletedOnboarding) {
      return OnboardingScreen(
        onGetStarted: () {
          setState(() {
            _hasCompletedOnboarding = true;
          });
        },
      );
    }

    final List<Widget> screens = [
      HomeDashboardScreen(
        onStartTalk: () => setState(() => _currentIndex = 1),
        onOpenPiConnect: () => setState(() => _currentIndex = 2),
        onOpenOwnerDashboard: () => setState(() => _currentIndex = 3),
        onOpenAuth: () => setState(() => _isLoggedIn = false),
        onOpenHistory: _navigateToHistory,
        parentName: _parentName,
      ),
      const RafikiMouthScreen(),
      const PiPairingScreen(),
      _isLoggedIn
          ? OwnerDashboardScreen(
              onLogout: () {
                setState(() {
                  _isLoggedIn = false;
                  _parentName = "Parent Rafiki";
                });
              },
            )
          : ParentAuthScreen(
              onLoginSuccess: (name, email) {
                setState(() {
                  _parentName = name;
                  _isLoggedIn = true;
                  _currentIndex = 3;
                });
              },
            ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppTheme.backgroundPrimary,
        indicatorColor: AppTheme.accentLime,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.home, color: Colors.black),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.mic, color: Colors.black),
            label: 'Talk',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.smart_toy, color: Colors.black),
            label: 'Rafiki',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.person, color: Colors.black),
            label: 'Parents',
          ),
        ],
      ),
    );
  }
}
