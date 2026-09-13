import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/unify_nav_shell.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/channels/presentation/screens/connected_accounts_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/inbox/presentation/providers/inbox_provider.dart';
import 'features/inbox/presentation/screens/call_screen.dart';
import 'features/inbox/presentation/screens/unified_inbox_screen.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.init();

  // Set default system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: UnifyApp(),
    ),
  );
}

class UnifyApp extends ConsumerWidget {
  const UnifyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: const SplashScreen(),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final inboxState = ref.watch(inboxProvider);
    final tenantName = authState.user?.currentTenant?.name ?? 'Acme Retail Group';

    final screens = [
      DashboardScreen(onNavigateTab: _onTabChanged),
      const UnifiedInboxScreen(),
      const ConnectedAccountsScreen(),
      const CallScreen(),
      const SettingsScreen(),
    ];

    return UnifyNavShell(
      currentIndex: _currentIndex,
      onIndexChanged: _onTabChanged,
      unreadInboxCount: inboxState.totalUnreadCount,
      unreadNotificationCount: 2,
      businessName: tenantName,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
