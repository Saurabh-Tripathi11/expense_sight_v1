// lib/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    signInOption: SignInOption.standard,
  );

  bool _isLoading = false;
  String? _error;
  GoogleSignInAccount? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  GoogleSignInAccount? get user => _user;

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Attempting Google Sign In...');

      // First try silent sign in
      debugPrint('Attempting silent sign in...');
      _user = await _googleSignIn.signInSilently();

      if (_user == null) {
        debugPrint('Silent sign in failed, attempting interactive sign in...');
        _user = await _googleSignIn.signIn();
      }

      if (_user == null) {
        debugPrint('Interactive sign in cancelled by user');
        _error = 'Sign in cancelled';
        notifyListeners();
        return false;
      }

      // Get authentication data
      debugPrint('Getting auth tokens...');
      final GoogleSignInAuthentication? googleAuth = await _user!.authentication;

      debugPrint('Auth token received: ${googleAuth?.accessToken != null}');

      if (googleAuth?.accessToken == null) {
        debugPrint('Failed to get auth tokens');
        _error = 'Failed to get authentication tokens';
        _user = null;
        notifyListeners();
        return false;
      }

      debugPrint('Successfully signed in as: ${_user!.email}');
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('Sign in error details: $e');
      _error = _getReadableErrorMessage(e.toString());
      _user = null;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getReadableErrorMessage(String error) {
    debugPrint('Raw error: $error');
    if (error.contains('network_error')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('sign_in_failed')) {
      return 'Sign in failed. Please verify Google Play Services is up to date.';
    } else if (error.contains('sign_in_canceled')) {
      return 'Sign in was cancelled.';
    } else if (error.contains('ApiException: 10')) {
      return 'Google Sign In configuration error. Please verify setup.';
    } else {
      return 'Error: $error';
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = _getReadableErrorMessage(e.toString());
      notifyListeners();
    }
  }
}