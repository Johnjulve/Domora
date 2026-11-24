import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches external HTTP/HTTPS URLs with fallback and explicit user-facing errors.
class ExternalUrlLauncher {
  const ExternalUrlLauncher({
    Future<bool> Function(Uri uri, {LaunchMode mode})? launcher,
  }) : _launcher = launcher ?? launchUrl;

  final Future<bool> Function(Uri uri, {LaunchMode mode}) _launcher;

  /// Opens an HTTP or HTTPS URL externally, falling back to platform default.
  ///
  /// Returns `null` on success, or a user-facing error message if the URL is
  /// invalid or cannot be opened.
  Future<String?> openHttpUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    final uri = Uri.tryParse(trimmed);
    final isValidHttp = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;

    if (!isValidHttp) {
      return 'Unable to open link: invalid URL.';
    }

    if (await _tryLaunch(uri, LaunchMode.externalApplication)) {
      return null;
    }

    if (await _tryLaunch(uri, LaunchMode.platformDefault)) {
      return null;
    }

    return 'Unable to open download link. Please check your browser settings or try again.';
  }

  Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await _launcher(uri, mode: mode);
    } catch (_) {
      // Platform launch exceptions are converted to false so openHttpUrl can try fallback or return an explicit error.
      return false;
    }
  }
}

/// Riverpod provider exposing [ExternalUrlLauncher].
final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>((ref) {
  return const ExternalUrlLauncher();
});
