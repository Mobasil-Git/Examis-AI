import 'package:examis_ai/model/onboardng_model.dart';
import 'package:examis_ai/pages/splash_screen.dart'; // Make sure this path is correct!
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../provider/app_state_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<OnboardingContent> contents = [
    OnboardingContent(
      title: "Upload Your Curriculum",
      description:
      "Simply upload your existing .pdf, .docx, or .pptx files. Exami AI will read and understand your material instantly.",
      lottiePath: "assets/animations/lottie_animations/upload.json",
    ),
    OnboardingContent(
      title: "Set Your Variations",
      description:
      "Choose how many MCQs, short, and long questions you need. Generate multiple unique variations to prevent cheating.",
      lottiePath: "assets/animations/lottie_animations/settings.json",
    ),
    OnboardingContent(
      title: "Download & Print",
      description:
      "Get perfectly formatted, ready-to-print assessment papers in seconds. Save hours of manual prep time.",
      lottiePath: "assets/animations/lottie_animations/download.json",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: contents.length,
              onPageChanged: (int index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (_, i) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- THE NEW STACK WITH THE BLOB BACKGROUND ---
                      SizedBox(
                        height: 350,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. The Organic Shape (Changes based on page index)
                            BlobBackground(pageIndex: i),

                            // 2. The Lottie Animation on top
                            Lottie.asset(
                              contents[i].lottiePath,
                              height: 280,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        contents[i].title,
                        textAlign: TextAlign.center,
                        style:  TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        contents[i].description,
                        textAlign: TextAlign.center,
                        style:  TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 16,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    contents.length,
                        (index) => buildDot(index, context),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (currentIndex == contents.length - 1) {
                      // Mark onboarding as complete & go to Splash Screen
                      context.read<AppStateProvider>().completeOnboarding();
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 800),
                          pageBuilder: (_, __, ___) => const SplashScreen(),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        currentIndex == contents.length - 1 ? "Get Started" : "Next",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      width: currentIndex == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentIndex == index ? AppColors.primary : context.border,
      ),
    );
  }
}

// --- THE CUSTOM FLUTTER BLOB WIDGET ---
class BlobBackground extends StatelessWidget {
  final int pageIndex;

  const BlobBackground({super.key, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    // We define 3 distinct asymmetrical border radii to create different shapes
    final List<BorderRadius> blobShapes = [
      // 1. Weight shifted top-left
      const BorderRadius.only(
        topLeft: Radius.circular(160),
        topRight: Radius.circular(100),
        bottomLeft: Radius.circular(100),
        bottomRight: Radius.circular(90),
      ),
      // 2. Weight shifted bottom-right
      const BorderRadius.only(
        topLeft: Radius.circular(110),
        topRight: Radius.circular(150),
        bottomLeft: Radius.circular(140),
        bottomRight: Radius.circular(100),
      ),
      // 3. Weight shifted top-right
      const BorderRadius.only(
        topLeft: Radius.circular(100),
        topRight: Radius.circular(170),
        bottomLeft: Radius.circular(120),
        bottomRight: Radius.circular(110),
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600), // Smoothly morphs when swiping!
      curve: Curves.easeInOut,
      height: context.heightPercent(0.5),
      width: context.widthPercent(0.9),
      decoration: BoxDecoration(
        // Using your super light blue theme color with a hint of transparency
        color: AppColors.primaryExtraLight.withAlpha(80),
        borderRadius: blobShapes[pageIndex],
      ),
    );
  }
}