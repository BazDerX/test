import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/room_design_screen.dart';
import 'screens/furniture_listing_screen.dart';
import 'services/furniture_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FurnitureStore.instance.loadCart();
  } catch (_) {
    FurnitureStore.instance.persistenceError =
        'Хадгалсан сагсыг уншиж чадсангүй.';
  }
  runApp(const SanaaApp());
}

class SanaaApp extends StatelessWidget {
  const SanaaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SANAA',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    routes: {
      '/': (_) => const WelcomeScreen(),
      '/login': (_) => const LoginScreen(),
      '/register': (_) => const RegisterScreen(),
      '/forgot-password': (_) => const ForgotPasswordScreen(),
      '/home': (_) => const HomeScreen(),
      '/room-design': (_) => const RoomDesignScreen(),
      '/furniture': (_) => const FurnitureListingScreen(),
    },
  );
}
