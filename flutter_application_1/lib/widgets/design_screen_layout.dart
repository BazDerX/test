import 'package:flutter/material.dart';

class DesignScreenLayout extends StatelessWidget {
  const DesignScreenLayout({
    super.key,
    required this.title,
    required this.children,
    this.bottomNavigationBar,
  });
  final String title;
  final List<Widget> children;
  final Widget? bottomNavigationBar;
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: bottomNavigationBar,
    appBar: AppBar(
      title: Text(title),
      leading: IconButton(
        tooltip: 'Буцах',
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}
