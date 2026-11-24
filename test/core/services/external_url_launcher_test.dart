import 'package:domora/core/services/external_url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('ExternalUrlLauncher', () {
    test('returns null and launches directly with externalApplication on success', () async {
      final calls = <(Uri, LaunchMode)>[];
      final launcher = ExternalUrlLauncher(
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          calls.add((uri, mode));
          return true;
        },
      );

      final error = await launcher.openHttpUrl(
        '  https://github.com/Johnjulve/Domora/releases/download/v0.2.0/app-release.apk  ',
      );

      expect(error, isNull);
      expect(calls, hasLength(1));
      expect(
        calls.single.$1,
        Uri.parse('https://github.com/Johnjulve/Domora/releases/download/v0.2.0/app-release.apk'),
      );
      expect(calls.single.$2, LaunchMode.externalApplication);
    });

    test('accepts http URLs', () async {
      final calls = <(Uri, LaunchMode)>[];
      final launcher = ExternalUrlLauncher(
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          calls.add((uri, mode));
          return true;
        },
      );

      final error = await launcher.openHttpUrl('http://example.com/domora.apk');

      expect(error, isNull);
      expect(calls, hasLength(1));
      expect(calls.single.$1, Uri.parse('http://example.com/domora.apk'));
      expect(calls.single.$2, LaunchMode.externalApplication);
    });

    test('falls back to platformDefault when externalApplication returns false', () async {
      final modes = <LaunchMode>[];
      final launcher = ExternalUrlLauncher(
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          modes.add(mode);
          return mode == LaunchMode.platformDefault;
        },
      );

      final error = await launcher.openHttpUrl('https://github.com/Johnjulve/Domora/releases');

      expect(error, isNull);
      expect(modes, [LaunchMode.externalApplication, LaunchMode.platformDefault]);
    });

    test('falls back to platformDefault when externalApplication throws', () async {
      final modes = <LaunchMode>[];
      final launcher = ExternalUrlLauncher(
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          modes.add(mode);
          if (mode == LaunchMode.externalApplication) {
            throw Exception('ActivityNotFoundException');
          }
          return true;
        },
      );

      final error = await launcher.openHttpUrl('https://github.com/Johnjulve/Domora/releases');

      expect(error, isNull);
      expect(modes, [LaunchMode.externalApplication, LaunchMode.platformDefault]);
    });

    test('returns user-facing error when both launch modes return false', () async {
      final modes = <LaunchMode>[];
      final launcher = ExternalUrlLauncher(
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          modes.add(mode);
          return false;
        },
      );

      final error = await launcher.openHttpUrl('https://github.com/Johnjulve/Domora/releases');

      expect(error, isNotNull);
      expect(error, isNotEmpty);
      expect(modes, [LaunchMode.externalApplication, LaunchMode.platformDefault]);
    });

    test('returns user-facing error when both launch modes throw', () async {
      final modes = <LaunchMode>[];
      final launcher = ExternalUrlLauncher(
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          modes.add(mode);
          throw StateError('No handler');
        },
      );

      final error = await launcher.openHttpUrl('https://github.com/Johnjulve/Domora/releases');

      expect(error, isNotNull);
      expect(error, isNotEmpty);
      expect(modes, [LaunchMode.externalApplication, LaunchMode.platformDefault]);
    });

    test('rejects empty, malformed, missing-host, and non-http(s) URLs without calling launcher',
        () async {
      var called = false;
      final launcher = ExternalUrlLauncher(
        launcher: (uri, {mode = LaunchMode.platformDefault}) async {
          called = true;
          return true;
        },
      );

      const invalidUrls = [
        '',
        '   ',
        'not a valid url',
        'ftp://example.com/app.apk',
        'file:///storage/emulated/0/app.apk',
        'javascript:alert(1)',
        'mailto:user@example.com',
        'https://',
        'http:///path-without-host',
        'http://[::1',
      ];

      for (final rawUrl in invalidUrls) {
        final error = await launcher.openHttpUrl(rawUrl);
        expect(error, isNotNull, reason: 'Expected rejection for "$rawUrl"');
        expect(error, isNotEmpty, reason: 'Expected non-empty error for "$rawUrl"');
      }

      expect(called, isFalse);
    });

    test('externalUrlLauncherProvider returns default launcher and supports overrides', () async {
      final defaultContainer = ProviderContainer();
      addTearDown(defaultContainer.dispose);
      expect(defaultContainer.read(externalUrlLauncherProvider), isA<ExternalUrlLauncher>());

      var overrideCalled = false;
      final overrideContainer = ProviderContainer(
        overrides: [
          externalUrlLauncherProvider.overrideWithValue(
            ExternalUrlLauncher(
              launcher: (uri, {mode = LaunchMode.platformDefault}) async {
                overrideCalled = true;
                return true;
              },
            ),
          ),
        ],
      );
      addTearDown(overrideContainer.dispose);

      final error = await overrideContainer
          .read(externalUrlLauncherProvider)
          .openHttpUrl('https://github.com/Johnjulve/Domora/releases');

      expect(error, isNull);
      expect(overrideCalled, isTrue);
    });
  });
}
