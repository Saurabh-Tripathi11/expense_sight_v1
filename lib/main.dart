// lib/main.dart

import 'package:expense_sight/presentation/screens/analytics/analytics_screen.dart';
import 'package:expense_sight/presentation/screens/auth/sign_in_screen.dart';
import 'package:expense_sight/presentation/screens/category/category_list_screen.dart';
import 'package:expense_sight/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database_helper.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
  await dbHelper.database; // Ensure database is initialized

  runApp(MyApp(dbHelper: dbHelper));
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
        // Add AuthProvider first
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(dbHelper),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(dbHelper),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Expense Sight',
            debugShowCheckedModeBanner: false,
            themeMode: settings.settings.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  physics: const BouncingScrollPhysics(),
                ),
                child: child!,
              );
            },
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // Show loading indicator while checking auth state
                if (auth.isLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                // Show sign in screen if not authenticated
                return const SignInScreen();
              },
            ),
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/categories': (context) => const CategoryListScreen(),
              '/analytics': (context) => const AnalyticsScreen(),
            },
          );
        },
      ),
    );
  }
}

// Global error boundary widget
class AppErrorBoundary extends StatelessWidget {
  final Widget child;

  const AppErrorBoundary({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, widget) {
        Widget error = const Text('...rendering error...');

        if (widget is Scaffold || widget is Navigator) {
          error = Scaffold(body: Center(child: error));
        }

        ErrorWidget.builder = (errorDetails) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorDetails.exception.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        };

        return widget ?? error;
      },
      home: child,
    );
  }
}