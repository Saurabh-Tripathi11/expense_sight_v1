// lib/presentation/screens/auth/sign_in_screen.dart

import 'package:expense_sight/presentation/screens/expense/expense_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fade_in_animation.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ExpenseListScreen(),
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Logo with animation
                    FadeInAnimation(
                      child: const _AppLogo(),
                    ),
                    const SizedBox(height: 48),
                    // Welcome text with animation
                    FadeInAnimation(
                      duration: const Duration(milliseconds: 700),
                      child: Text(
                        AppConstants.welcomeMessage,
                        style: AppTheme.headline2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Sign in button with animation
                    FadeInAnimation(
                      duration: const Duration(milliseconds: 900),
                      child: const _SignInButton(),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatefulWidget {
  const _SignInButton({Key? key}) : super(key: key);

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool _isProcessing = false;

  Future<void> _handleSignIn(BuildContext context) async {
    if (_isProcessing) return; // Prevent multiple taps

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('Handling sign in tap...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signInWithGoogle();
      debugPrint('Sign in success: $success');

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ExpenseListScreen(),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Sign in failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading || _isProcessing) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text(AppConstants.googleSignInButton),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isProcessing ? null : () => _handleSignIn(context),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 16),
              Text(
                auth.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
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
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet,
        size: 48,
        color: Colors.white,
      ),
    );
  }
}