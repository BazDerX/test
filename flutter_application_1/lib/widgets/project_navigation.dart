import 'package:flutter/material.dart';

import 'bottom_navigation.dart';
import '../screens/home_screen.dart';

class ProjectNavigation extends StatelessWidget {
  const ProjectNavigation({super.key});
  @override
  Widget build(BuildContext context) => SanaaBottomNavigation(
    selected: 3,
    onSelected: (index) => Navigator.pushAndRemoveUntil<void>(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(initialTab: index)),
      (_) => false,
    ),
  );
}
