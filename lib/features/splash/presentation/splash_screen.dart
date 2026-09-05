import 'package:flutter/material.dart';
import 'package:agroconnect/core/constants/app_colors.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';
import 'package:agroconnect/features/onboarding/presentation/onboarding_screen.dart';
import 'package:agroconnect/features/buyer/presentation/buyer_home_screen.dart';
import 'package:agroconnect/features/farmer/presentation/farmer_home_screen.dart';
import 'package:agroconnect/features/admin/presentation/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check whether Firebase already has a signed-in user.
    final isAuthenticated =
        AuthService.instance.isAuthenticated;

    if (!isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
      return;
    }

    // Load the current user's Firestore profile.
    final user =
        await AuthService.instance.loadCurrentUserProfile();

    if (!mounted) return;

    // If the Firebase account exists but the profile
    // could not be loaded, return to onboarding/login flow.
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
      return;
    }

    switch (user.role) {
      case 'Buyer':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BuyerHomeScreen(),
          ),
        );
        break;

      case 'Farmer':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const FarmerHomeScreen(),
          ),
        );
        break;

      case 'Admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminHomeScreen(),
          ),
        );
        break;

      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.eco,
                size: 100,
                color: AppColors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'AgroConnect',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Connecting Farmers and Buyers',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}