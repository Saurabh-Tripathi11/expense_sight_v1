import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database_helper.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/search_filter_provider.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/screens/auth/sign_in_screen.dart';

// Custom scroll behavior to enable smooth scrolling
class CustomScrollBehavior extends ScrollBehavior {
  const CustomScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable high refresh rate support
  await _enableHighRefreshRate();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize database
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;

  runApp(MyApp(dbHelper: dbHelper));
}

Future<void> _enableHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();

    // Get all supported modes
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    // Find modes with the same resolution as the active mode
    final List<DisplayMode> sameResolution = supported
        .where((DisplayMode m) =>
    m.width == active.width && m.height == active.height)
        .toList()
      ..sort((DisplayMode a, DisplayMode b) =>
          b.refreshRate.compareTo(a.refreshRate));

    // Set the highest refresh rate mode
    if (sameResolution.isNotEmpty) {
      await FlutterDisplayMode.setPreferredMode(sameResolution.first);
      debugPrint('Display mode set to: ${sameResolution.first.refreshRate}Hz');
    }
  } catch (e) {
    debugPrint('Failed to set high refresh rate: $e');
  }
}

class MyApp extends StatelessWidget {
  final DatabaseHelper dbHelper;

  const MyApp({
    Key? key,
    required this.dbHelper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(dbHelper)),
        ChangeNotifierProvider(create: (_) => CategoryProvider(dbHelper)),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(dbHelper)),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider(dbHelper)),
        ChangeNotifierProvider(create: (_) => SearchFilterProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Expense Sight',
            debugShowCheckedModeBanner: false,
            themeMode: settings.settings.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            scrollBehavior: const CustomScrollBehavior(),
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const CustomScrollBehavior(),
                child: child!,
              );
            },
            home: const SignInScreen(),
          );
        },
      ),
    );
  }
}