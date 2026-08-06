import 'package:flutter/material.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'core/theme/app_theme.dart';

class AgroConnectApp extends StatelessWidget {
  const AgroConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgroConnect',
theme: AppTheme.lightTheme,
     home:  OnboardingScreen(),
    );
  }
}