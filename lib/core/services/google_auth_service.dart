import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service wrapping GoogleSignIn to handle OAuth2 authentication for Google Drive Cloud Redundancy.
class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;
  String? _lastError;

  /// Google Web / OAuth2 Client ID for Domora
  static const String clientId =
      '767402822106-btgbm208ccgv8n6fsh2g8umnajsimg44.apps.googleusercontent.com';

  /// Scopes required: email identification and sandboxed private App Data folder access on Google Drive
  static const List<String> scopes = [
    'email',
    'https://www.googleapis.com/auth/drive.appdata',
  ];

  /// The currently signed-in Google account, or null if signed out.
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Human-readable error from the most recent [signIn] attempt, or null if
  /// the attempt succeeded, was cancelled by the user, or has not run.
  String? get lastError => _lastError;

  /// Ensures GoogleSignIn is initialized with the platform-appropriate client ID.
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await _googleSignIn.initialize(
      clientId: kIsWeb ? clientId : null,
      serverClientId: kIsWeb ? null : clientId,
    );
    _isInitialized = true;
  }

  /// Triggers the interactive Google sign-in flow.
  ///
  /// Returns the authenticated [GoogleSignInAccount] on success,
  /// or null if the user cancels or an error occurs.
  Future<GoogleSignInAccount?> signIn() async {
    _lastError = null;
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate(scopeHint: scopes);
      _currentUser = account;
      return account;
    } on GoogleSignInException catch (e, stack) {
      debugPrint('GoogleAuthService.signIn failed: $e\n$stack');
      if (e.code != GoogleSignInExceptionCode.canceled) {
        final description = e.description?.trim();
        _lastError = description != null && description.isNotEmpty
            ? 'Google sign-in failed (${e.code.name}): $description'
            : 'Google sign-in failed (${e.code.name})';
      }
      return null;
    } catch (e, stack) {
      debugPrint('GoogleAuthService.signIn failed: $e\n$stack');
      _lastError = 'Google sign-in failed: $e';
      return null;
    }
  }

  /// Signs out the currently authenticated user and clears local session state.
  Future<void> signOut() async {
    _lastError = null;
    try {
      await _googleSignIn.signOut();
    } catch (e, stack) {
      debugPrint('GoogleAuthService.signOut failed: $e\n$stack');
    } finally {
      _currentUser = null;
    }
  }
}

/// Riverpod provider exposing [GoogleAuthService].
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});
