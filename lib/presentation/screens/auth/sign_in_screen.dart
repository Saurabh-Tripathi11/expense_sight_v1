import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_animation.dart';
import '../../providers/auth_provider.dart';
import '../expense/expense_list_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FadeInAnimation(
                child: const _AppLogo(),
              ),
              const SizedBox(height: 48),
              FadeInAnimation(
                duration: const Duration(milliseconds: 700),
                child: Text(
                  AppConstants.welcomeMessage,
                  style: AppTheme.headline2,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              FadeInAnimation(
                duration: const Duration(milliseconds: 900),
                child: const _SignInButton(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({Key? key}) : super(key: key);

  Future<void> _handleSignIn(BuildContext context) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await context.read<AuthProvider>().signInWithGoogle();

    if (success) {
      // Navigate to ExpenseListScreen and remove all previous routes
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const ExpenseListScreen(),
        ),
            (route) => false, // This removes all previous routes
      );
    } else {
      // Show error message
      final error = context
          .read<AuthProvider>()
          .error;
      if (error != null) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const CircularProgressIndicator();
        }

        return Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text(AppConstants.googleSignInButton),
              onPressed: () => _handleSignIn(context),
            ),
            if (authProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  authProvider.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(
        Icons.account_balance_wallet,
        size: 48,
        color: Colors.white,
      ),
    );
  }
}
