// lib/core/constants/app_constants.dart

class AppConstants {
  // App Information
  static const String appName = 'Expense Sight';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Authentication Messages
  static const String welcomeMessage = 'Track Expenses Effortlessly';
  static const String googleSignInButton = 'Continue with Google';
  static const String signInError = 'Sign in failed. Please try again.';
  static const String signOutError = 'Sign out failed. Please try again.';

  // Database Constants
  static const String databaseName = 'expense_sight.db';
  static const int databaseVersion = 1;

  // Storage Keys
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String currencyKey = 'app_currency';
  static const String notificationKey = 'notifications_enabled';
  static const String biometricsKey = 'biometrics_enabled';

  // Error Messages
  static const String generalError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String databaseError = 'Database error occurred.';
  static const String unauthorizedError = 'Please sign in to continue.';

  // Success Messages
  static const String expenseAdded = 'Expense added successfully';
  static const String expenseUpdated = 'Expense updated successfully';
  static const String expenseDeleted = 'Expense deleted successfully';
  static const String categoryAdded = 'Category added successfully';
  static const String settingsSaved = 'Settings saved successfully';

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Validation Constants
  static const int maxExpenseAmount = 999999999;
  static const int maxNoteLength = 500;
  static const int maxCategoryNameLength = 30;

  // API Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Cache Duration
  static const int analyticsCacheDuration = 3600; // 1 hour in seconds

  // UI Constants
  static const double appBarHeight = 56.0;
  static const double bottomNavBarHeight = 60.0;
  static const double fabBottomMargin = 70.0;
  static const double cardBorderRadius = 12.0;
  static const double inputBorderRadius = 8.0;

  // Padding and Margin
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // Font Sizes
  static const double fontSizeXS = 12.0;
  static const double fontSizeSM = 14.0;
  static const double fontSizeMD = 16.0;
  static const double fontSizeLG = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;

  // Default Values
  static const String defaultCurrency = 'USD';
  static const String defaultLanguage = 'en';
  static const String defaultDateFormat = 'MM/dd/yyyy';

  // Feature Flags
  static const bool enableBiometrics = true;
  static const bool enableNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableBackup = true;
  static const bool enableDarkMode = true;

  // Support Information
  static const String supportEmail = 'support@expensesight.com';
  static const String privacyPolicyUrl = 'https://expensesight.com/privacy';
  static const String termsOfServiceUrl = 'https://expensesight.com/terms';
  static const String helpCenterUrl = 'https://expensesight.com/help';
}