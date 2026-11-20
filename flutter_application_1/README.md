# SANAA

Flutter Material 3 welcome and login screens based on the images in `references/`.

Run with `flutter pub get` and `flutter run`. Validate with `flutter analyze` and `flutter test`.

- `lib/main.dart`: application entry point and named navigation routes.
- `lib/theme/app_theme.dart`: shared colors, typography, buttons and field styling.
- `lib/screens/welcome_screen.dart`: responsive onboarding layout.
- `lib/screens/login_screen.dart`: email/Mongolian phone validation, password visibility, autofill, keyboard handling and pending state.
- `lib/screens/register_screen.dart` and `forgot_password_screen.dart`: explicit placeholder destinations.
- `lib/widgets/`: reusable buttons, labeled fields and placeholder page layout.
- `assets/images/living_room.png`: clean photo crop from the welcome reference (x=1, y=137, width=388, height=390). No screenshot UI is rendered as an asset.
- `pubspec.yaml`: image asset registration; no dependencies added.
- `test/widget_test.dart`: navigation, validation, password toggle, pending state, and small viewport/keyboard checks.

Authentication is not connected. Login displays an explicit Mongolian notice after a short local loading preview. Inject `LoginScreen.loginRequest` to integrate an authentication service. Registration and password recovery do not submit data.

The welcome headline follows the supplied Mongolian brief rather than the romanized text in the screenshot. Native system status/navigation bars provide the device chrome. On wide displays content is limited to 520 logical pixels; smaller screens and the keyboard use scrolling.
