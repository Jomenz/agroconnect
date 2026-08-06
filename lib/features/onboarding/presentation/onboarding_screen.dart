import 'package:flutter/material.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              children: const [
                OnboardingPage(
                  icon: Icons.eco,
                  title: 'Welcome to AgroConnect',
                  description:
                      'Buy and sell fresh farm produce directly from trusted farmers.',
                ),
                OnboardingPage(
                  icon: Icons.storefront,
                  title: 'Find Quality Products',
                  description:
                      'Browse a variety of agricultural products at affordable prices.',
                ),
                OnboardingPage(
                  icon: Icons.local_shipping,
                  title: 'Fast & Secure Delivery',
                  description:
                      'Receive your orders safely and conveniently at your location.',
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.all(4),
                width: currentPage == index ? 14 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: currentPage == index
                      ? Colors.green
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}