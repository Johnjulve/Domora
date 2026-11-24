import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// Renders the official Google Identity Services sign-in button on Web.
Widget renderGoogleSignInWebButton() {
  return gsi_web.renderButton(
    configuration: gsi_web.GSIButtonConfiguration(
      type: gsi_web.GSIButtonType.standard,
      theme: gsi_web.GSIButtonTheme.outline,
      size: gsi_web.GSIButtonSize.large,
      text: gsi_web.GSIButtonText.continueWith,
      shape: gsi_web.GSIButtonShape.rectangular,
    ),
  );
}
