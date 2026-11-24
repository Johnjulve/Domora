import 'package:domora/core/services/google_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class _FakeGoogleSignInAccount implements GoogleSignInAccount {
  _FakeGoogleSignInAccount({required this.email});

  @override
  final String email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleSignIn implements GoogleSignIn {
  _FakeGoogleSignIn({
    this.accountToReturn,
    this.initializeError,
    this.authenticateError,
  });

  final GoogleSignInAccount? accountToReturn;
  Object? initializeError;
  Object? authenticateError;

  int initializeCalls = 0;
  int authenticateCalls = 0;
  int signOutCalls = 0;
  String? capturedClientId;
  String? capturedServerClientId;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializeCalls++;
    capturedClientId = clientId;
    capturedServerClientId = serverClientId;
    if (initializeError != null) {
      throw initializeError!;
    }
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const <String>[],
  }) async {
    authenticateCalls++;
    if (authenticateError != null) {
      throw authenticateError!;
    }
    return accountToReturn!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WebGoogleAuthService extends GoogleAuthService {
  _WebGoogleAuthService({required super.googleSignIn});

  @override
  bool get usesWebSignInButton => true;
}

void main() {
  group('GoogleAuthService', () {
    test('passes serverClientId and null clientId to initialize on non-web', () async {
      final account = _FakeGoogleSignInAccount(email: 'user@example.com');
      final fakeSignIn = _FakeGoogleSignIn(accountToReturn: account);
      final service = GoogleAuthService(googleSignIn: fakeSignIn);

      final result = await service.signIn();

      expect(result, same(account));
      expect(service.currentUser, same(account));
      expect(service.lastError, isNull);
      expect(fakeSignIn.initializeCalls, 1);
      expect(fakeSignIn.capturedClientId, isNull);
      expect(fakeSignIn.capturedServerClientId, GoogleAuthService.clientId);
      expect(fakeSignIn.authenticateCalls, 1);
    });

    test('leaves lastError null when user cancels sign-in', () async {
      final fakeSignIn = _FakeGoogleSignIn(
        authenticateError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'User cancelled',
        ),
      );
      final service = GoogleAuthService(googleSignIn: fakeSignIn);

      final result = await service.signIn();

      expect(result, isNull);
      expect(service.lastError, isNull);
      expect(service.currentUser, isNull);
    });

    test('sets lastError and skips authenticate when initialize throws GoogleSignInException', () async {
      final fakeSignIn = _FakeGoogleSignIn(
        initializeError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
          description: 'serverClientId must be provided on Android',
        ),
      );
      final service = GoogleAuthService(googleSignIn: fakeSignIn);

      final result = await service.signIn();

      expect(result, isNull);
      expect(fakeSignIn.authenticateCalls, 0);
      expect(service.lastError, contains('clientConfigurationError'));
      expect(service.lastError, contains('serverClientId must be provided on Android'));
    });

    test('sets lastError on non-GoogleSignInException and clears it on retry or signOut', () async {
      final account = _FakeGoogleSignInAccount(email: 'user@example.com');
      final fakeSignIn = _FakeGoogleSignIn(
        accountToReturn: account,
        authenticateError: StateError('network unavailable'),
      );
      final service = GoogleAuthService(googleSignIn: fakeSignIn);

      final failedResult = await service.signIn();
      expect(failedResult, isNull);
      expect(service.lastError, contains('network unavailable'));

      // signOut clears lastError
      await service.signOut();
      expect(service.lastError, isNull);
      expect(fakeSignIn.signOutCalls, 1);

      // Subsequent signIn resets lastError and succeeds
      fakeSignIn.authenticateError = null;
      final successResult = await service.signIn();
      expect(successResult, same(account));
      expect(service.lastError, isNull);
    });

    test('initialize() delegates to GoogleSignIn.initialize once', () async {
      final fakeSignIn = _FakeGoogleSignIn();
      final service = GoogleAuthService(googleSignIn: fakeSignIn);

      await service.initialize();
      await service.initialize();

      expect(fakeSignIn.initializeCalls, 1);
      expect(fakeSignIn.capturedServerClientId, GoogleAuthService.clientId);
    });

    test('recordSignedInAccount sets currentUser and clears lastError', () async {
      final account = _FakeGoogleSignInAccount(email: 'web@example.com');
      final fakeSignIn = _FakeGoogleSignIn(
        authenticateError: StateError('prior error'),
      );
      final service = GoogleAuthService(googleSignIn: fakeSignIn);

      await service.signIn();
      expect(service.lastError, isNotNull);

      service.recordSignedInAccount(account);
      expect(service.currentUser, same(account));
      expect(service.lastError, isNull);
    });

    test('signIn() returns null with guidance when usesWebSignInButton is true', () async {
      final fakeSignIn = _FakeGoogleSignIn();
      final service = _WebGoogleAuthService(googleSignIn: fakeSignIn);

      final result = await service.signIn();

      expect(result, isNull);
      expect(service.lastError, 'Use the Google Sign-In button to continue on Web.');
      expect(fakeSignIn.initializeCalls, 0);
      expect(fakeSignIn.authenticateCalls, 0);
    });
  });
}
