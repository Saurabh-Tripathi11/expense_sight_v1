// lib/presentation/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;

          return ListView(
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(
                  settings.themeMode == ThemeMode.system
                      ? 'System'
                      : settings.themeMode == ThemeMode.light
                      ? 'Light'
                      : 'Dark',
                ),
                onTap: () => _showThemePicker(context, provider),
              ),
              ListTile(
                title: const Text('Currency'),
                subtitle: Text(settings.currency),
                onTap: () => _showCurrencyPicker(context, provider),
              ),
              SwitchListTile(
                title: const Text('Show Decimals'),
                subtitle: const Text('Show decimal places in amounts'),
                value: settings.showDecimals,
                onChanged: (value) => provider.setShowDecimals(value),
              ),
              SwitchListTile(
                title: const Text('Group Expenses'),
                subtitle: const Text('Group expenses by date'),
                value: settings.groupExpenses,
                onChanged: (value) => provider.setGroupExpenses(value),
              ),
              ListTile(
                title: const Text('Date Format'),
                subtitle: Text(settings.dateFormat),
                onTap: () => _showDateFormatPicker(context, provider),
              ),
              SwitchListTile(
                title: const Text('Use Biometrics'),
                subtitle: const Text('Secure app with fingerprint/face'),
                value: settings.useBiometrics,
                onChanged: (value) => provider.setUseBiometrics(value),
              ),
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Get daily expense reminders'),
                value: settings.enableNotifications,
                onChanged: (value) => provider.setEnableNotifications(value),
              ),
              if (settings.enableNotifications)
                ListTile(
                  title: const Text('Reminder Time'),
                  subtitle: Text(
                    settings.dailyReminderTime != null
                        ? '${settings.dailyReminderTime!.format(context)}'
                        : 'Not set',
                  ),
                  onTap: () => _showTimePicker(context, provider),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context, SettingsProvider provider) async {
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ThemeMode.system),
            child: const Text('System'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ThemeMode.light),
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ThemeMode.dark),
            child: const Text('Dark'),
          ),
        ],
      ),
    );

    if (result != null) {
      await provider.setThemeMode(result);
    }
  }

  Future<void> _showCurrencyPicker(BuildContext context, SettingsProvider provider) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Currency'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'USD'),
            child: const Text('USD (\$)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'EUR'),
            child: const Text('EUR (€)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'GBP'),
            child: const Text('GBP (£)'),
          ),
          // Add more currencies as needed
        ],
      ),
    );

    if (result != null) {
      await provider.setCurrency(result);
    }
  }

  Future<void> _showDateFormatPicker(BuildContext context, SettingsProvider provider) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Date Format'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'MM/dd/yyyy'),
            child: const Text('MM/dd/yyyy'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'dd/MM/yyyy'),
            child: const Text('dd/MM/yyyy'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'yyyy/MM/dd'),
            child: const Text('yyyy/MM/dd'),
          ),
        ],
      ),
    );

    if (result != null) {
      await provider.setDateFormat(result);
    }
  }

  Future<void> _showTimePicker(BuildContext context, SettingsProvider provider) async {
    final time = await showTimePicker(
      context: context,
      initialTime: provider.settings.dailyReminderTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      await provider.setDailyReminderTime(time);
    }
  }
}