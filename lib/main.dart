import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/storage_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/providers/api_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/feed/screens/feed_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/create_post/screens/create_post_screen.dart';
import 'features/messaging/screens/messaging_center_screen.dart';
import 'features/search/screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();

  // Initialize SharedPreferences early and store the instance
  await initializeSharedPreferences();

  // Migrate tokens from SharedPreferences to secure storage (one-time)
  final secureStorage = SecureStorageService();
  await secureStorage.migrateFromSharedPreferences();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'TheAuraHouse',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) {
          final authState = ref.watch(authProvider);

          // Show loading screen while checking authentication
          if (authState.isLoading) {
            return const _SplashScreen();
          }

          // Show main app if authenticated, otherwise show login
          if (authState.isAuthenticated) {
            return const MainNavigation();
          }
          return const LoginScreen();
        },
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  final List<Widget> _screens = [
    const FeedScreen(key: ValueKey('feed')),
    const SearchScreen(key: ValueKey('search')), // Search
    const FeedScreen(
      key: ValueKey('create'),
    ), // Create placeholder (not used, navigates to create screen)
    const MessagingCenterScreen(
      key: ValueKey('activity'),
    ), // Activity placeholder
    const ProfileScreen(key: ValueKey('profile')), // Profile
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _onWillPop(bool isDark) async {
    final now = DateTime.now();

    // If not on home screen, navigate to home
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false; // Don't exit app
    }

    // If on home screen, check for double back press to exit
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit'),
          duration: const Duration(seconds: 2),
          backgroundColor: isDark
              ? Colors.black.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return false; // Don't exit app
    }

    return true; // Exit app
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _onWillPop(isDark).then((shouldPop) {
            if (shouldPop && mounted) {
              // Exit app
              SystemNavigator.pop();
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: RepaintBoundary(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.fastOutSlowIn,
            switchOutCurve: Curves.fastOutSlowIn,
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Create staggered animations for ultra-smooth effect
              final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                ),
              );

              final slideAnimation =
                      Tween<Offset>(
                    begin: const Offset(0.015, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                      curve: const Interval(
                        0.0,
                        1.0,
                        curve: Curves.fastOutSlowIn,
                      ),
                    ),
                  );

              final scaleAnimation = Tween<double>(begin: 0.995, end: 1.0)
                  .animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(
                        0.0,
                        0.8,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  );

              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: ScaleTransition(scale: scaleAnimation, child: child),
                ),
              );
            },
            child: _screens[_currentIndex],
          ),
        ),
        bottomNavigationBar: RepaintBoundary(
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 64,
                      maxHeight: 64,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_filled,
                          index: 0,
                        ),
                        _buildNavItem(
                          icon: Icons.explore_outlined,
                          activeIcon: Icons.explore,
                          index: 1,
                        ),
                        _buildNavItem(
                          icon: Icons.add_circle_outline,
                          activeIcon: Icons.add_circle,
                          index: 2,
                          isCenter: true,
                        ),
                        _buildNavItem(
                          icon: Icons.chat_bubble_outline,
                          activeIcon: Icons.chat_bubble,
                          index: 3,
                        ),
                        _buildNavItem(
                          icon: Icons.account_circle_outlined,
                          activeIcon: Icons.account_circle,
                          index: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    bool isCenter = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = _currentIndex == index;

    if (isCenter) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF3B82F6)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.18))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedScale(
            scale: isActive ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.fastOutSlowIn,
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.65)
                        : Colors.black.withValues(alpha: 0.65)),
              size: isActive ? 28 : 26,
            ),
          ),
        ),
      ),
    );
  }
}
