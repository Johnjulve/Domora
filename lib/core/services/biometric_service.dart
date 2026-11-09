import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Service wrapping native biometric hardware enclave authentication.
/// Defensive exception handling ensures hardware absence or platform failures
/// never crash Domora.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  /// Checks if the host device hardware supports biometric authentication.
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Checks whether biometrics can currently be checked (enrolled & available).
  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Triggers the native platform biometric authentication prompt.
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
    bool persistAcrossBackgrounding = true,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: persistAcrossBackgrounding,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Provider exposing the singleton [BiometricService].
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
