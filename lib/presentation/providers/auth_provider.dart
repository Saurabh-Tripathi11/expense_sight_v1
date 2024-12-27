import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  bool _isLoading = false;
  String? _error;
  GoogleSignInAccount? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  GoogleSignInAccount? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    debugPrint('Checking current user...');
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _googleSignIn.signInSilently();
      debugPrint(_user != null
          ? 'Found signed in user: ${_user!.email}'
          : 'No signed in user found');
    } catch (e) {
      debugPrint('Error checking current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Starting Google Sign In...');

      // First try silent sign in
      debugPrint('Attempting silent sign in...');
      _user = await _googleSignIn.signInSilently();

      if (_user == null) {
        // If silent sign in fails, try interactive sign in
        debugPrint('Silent sign in failed, attempting interactive sign in...');
        _user = await _googleSignIn.signIn();
        debugPrint(_user == null
            ? 'Interactive sign in failed'
            : 'Interactive sign in successful');
      }

      if (_user == null) {
        debugPrint('Sign in cancelled by user');
        _error = 'Sign in cancelled';
        notifyListeners();
        return false;
      }

      // Get authentication data
      debugPrint('Getting auth tokens...');
      final GoogleSignInAuthentication? googleAuth = await _user!.authentication;

      if (googleAuth?.accessToken == null) {
        debugPrint('Failed to get authentication tokens');
        _error = 'Failed to get authentication tokens';
        _user = null;
        notifyListeners();
        return false;
      }

      debugPrint('Successfully signed in as: ${_user!.email}');
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('Sign in error: $e');
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
    } else if (error.contains('PlatformException')) {
      return 'Please check your Google Play Services configuration.';
    } else {
      return 'Error: $error';
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('Signing out...');
      _isLoading = true;
      notifyListeners();

      await _googleSignIn.signOut();
      _user = null;
      _error = null;
      debugPrint('Successfully signed out');

    } catch (e) {
      debugPrint('Sign out error: $e');
      _error = _getReadableErrorMessage(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}