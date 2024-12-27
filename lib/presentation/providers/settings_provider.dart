// lib/presentation/providers/settings_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/database/database_helper.dart';

class Settings {
  final String currency;
  final String locale;
  final ThemeMode themeMode;
  final bool useBiometrics;
  final bool showDecimals;
  final String dateFormat;
  final bool groupExpenses;
  final int firstDayOfWeek;
  final bool enableNotifications;
  final TimeOfDay? dailyReminderTime;

  const Settings({
    this.currency = 'USD',
    this.locale = 'en_US',
    this.themeMode = ThemeMode.system,
    this.useBiometrics = false,
    this.showDecimals = true,
    this.dateFormat = 'MM/dd/yyyy',
    this.groupExpenses = true,
    this.firstDayOfWeek = 1, // Monday
    this.enableNotifications = true,
    this.dailyReminderTime,
  });

  Settings copyWith({
    String? currency,
    String? locale,
    ThemeMode? themeMode,
    bool? useBiometrics,
    bool? showDecimals,
    String? dateFormat,
    bool? groupExpenses,
    int? firstDayOfWeek,
    bool? enableNotifications,
    TimeOfDay? dailyReminderTime,
  }) {
    return Settings(
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      showDecimals: showDecimals ?? this.showDecimals,
      dateFormat: dateFormat ?? this.dateFormat,
      groupExpenses: groupExpenses ?? this.groupExpenses,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': currency,
      'locale': locale,
      'themeMode': themeMode.index,
      'useBiometrics': useBiometrics,
      'showDecimals': showDecimals,
      'dateFormat': dateFormat,
      'groupExpenses': groupExpenses,
      'firstDayOfWeek': firstDayOfWeek,
      'enableNotifications': enableNotifications,
      'dailyReminderTime': dailyReminderTime != null
          ? '${dailyReminderTime!.hour}:${dailyReminderTime!.minute}'
          : null,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    String? reminderTimeStr = json['dailyReminderTime'] as String?;
    TimeOfDay? reminderTime;

    if (reminderTimeStr != null) {
      final parts = reminderTimeStr.split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Settings(
      currency: json['currency'] as String,
      locale: json['locale'] as String,
      themeMode: ThemeMode.values[json['themeMode'] as int],
      useBiometrics: json['useBiometrics'] as bool,
      showDecimals: json['showDecimals'] as bool,
      dateFormat: json['dateFormat'] as String,
      groupExpenses: json['groupExpenses'] as bool,
      firstDayOfWeek: json['firstDayOfWeek'] as int,
      enableNotifications: json['enableNotifications'] as bool,
      dailyReminderTime: reminderTime,
    );
  }
}

class SettingsProvider with ChangeNotifier {
  final DatabaseHelper _db;
  Settings _settings = const Settings();
  bool _isLoading = false;
  String? _error;

  SettingsProvider(this._db) {
    _loadSettings();
  }

  Settings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadSettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final settingsJson = await _db.getSetting('app_settings');
      if (settingsJson != null) {
        _settings = Settings.fromJson(jsonDecode(settingsJson));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load settings: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(Settings newSettings) async {
    try {
      await _db.setSetting(
        'app_settings',
        jsonEncode(newSettings.toJson()),
      );
      _settings = newSettings;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update settings: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  // Individual setting updates
  Future<void> setCurrency(String currency) async {
    await updateSettings(_settings.copyWith(currency: currency));
  }

  Future<void> setLocale(String locale) async {
    await updateSettings(_settings.copyWith(locale: locale));
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await updateSettings(_settings.copyWith(themeMode: themeMode));
  }

  Future<void> setUseBiometrics(bool useBiometrics) async {
    await updateSettings(_settings.copyWith(useBiometrics: useBiometrics));
  }

  Future<void> setShowDecimals(bool showDecimals) async {
    await updateSettings(_settings.copyWith(showDecimals: showDecimals));
  }

  Future<void> setDateFormat(String dateFormat) async {
    await updateSettings(_settings.copyWith(dateFormat: dateFormat));
  }

  Future<void> setGroupExpenses(bool groupExpenses) async {
    await updateSettings(_settings.copyWith(groupExpenses: groupExpenses));
  }

  Future<void> setFirstDayOfWeek(int firstDayOfWeek) async {
    await updateSettings(_settings.copyWith(firstDayOfWeek: firstDayOfWeek));
  }

  Future<void> setEnableNotifications(bool enableNotifications) async {
    await updateSettings(_settings.copyWith(enableNotifications: enableNotifications));
  }

  Future<void> setDailyReminderTime(TimeOfDay? time) async {
    await updateSettings(_settings.copyWith(dailyReminderTime: time));
  }

  // Reset settings to defaults
  Future<void> resetToDefaults() async {
    await updateSettings(const Settings());
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}