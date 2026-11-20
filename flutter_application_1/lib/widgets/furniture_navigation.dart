import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import 'bottom_navigation.dart';

class FurnitureNavigation extends StatelessWidget {
  const FurnitureNavigation({super.key});
  @override
  Widget build(BuildContext context) => SanaaBottomNavigation(
    selected: 1,
    onSelected: (index) {
      Navigator.pushAndRemoveUntil<void>(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(initialTab: index)),
        (_) => false,
      );
    },
  );
}
