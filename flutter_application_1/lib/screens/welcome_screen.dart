import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 26, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SANAA',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'AI + AR',
                        style: TextStyle(fontSize: 12, color: AppTheme.green),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/living_room.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ТАНЫ ГЭР. ТАНЫ САНАА.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.green,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'ЕНГИЙН ЭХЛЭЛ\nЭНД БАЙНА',
                        style: TextStyle(
                          fontSize: 32,
                          height: 1.44,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Өрөөгөө зурагла. AI-аар тохижуул. Тавилгаа авахаасаа өмнө AR-аар туршаарай.',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: List.generate(
                          3,
                          (i) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: i == 0 ? 24 : 6,
                            height: 5,
                            decoration: BoxDecoration(
                              color: i == 0 ? AppTheme.green : AppTheme.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Бүртгүүлэх',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'Нэвтрэх',
                        secondary: true,
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
