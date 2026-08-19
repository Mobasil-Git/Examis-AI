import 'package:examisai/data/local/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/onboarding_model.dart';
import '../utils/responsive_ui.dart';
import '../utils/routes/route_names.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
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
      description: "Simply upload your existing .pdf, .docx, or .pptx files. Exami AI will read and understand your material instantly.",
      lottiePath: "assets/animations/lottie_animations/upload.json",
    ),
    OnboardingContent(
      title: "Set Your Variations",
      description: "Choose how many MCQs, short, and long questions you need. Generate multiple unique variations to prevent cheating.",
      lottiePath: "assets/animations/lottie_animations/settings.json",
    ),
    OnboardingContent(
      title: "Download & Print",
      description: "Get perfectly formatted, ready-to-print assessment papers in seconds. Save hours of manual prep time.",
      lottiePath: "assets/animations/lottie_animations/download.json",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  padding: EdgeInsets.all(context.widthPercent(0.1)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: context.heightPercent(0.4),
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            BlobBackground(pageIndex: i),
                            Lottie.asset(
                              contents[i].lottiePath,
                              height: context.heightPercent(0.3),
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.04)),
                      Text(
                        contents[i].title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: context.isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: context.heightPercent(0.02)),
                      Text(
                        contents[i].description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: context.isMobile ? 16 : 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.widthPercent(0.06),
                vertical: context.heightPercent(0.03)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    contents.length,
                        (index) => buildDot(index, context, colorScheme),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (currentIndex == contents.length - 1) {
                      // Save directly to SharedPreferences
                      await SharedPrefManager().completeFirstTimeLaunch();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, RouteNames.login);
                      }
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    height: context.heightPercent(0.06),
                    padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06)),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        currentIndex == contents.length - 1 ? "Get Started" : "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 16 : 18,
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

  Widget buildDot(int index, BuildContext context, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      width: currentIndex == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentIndex == index ? colorScheme.primary : colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }
}

class BlobBackground extends StatelessWidget {
  final int pageIndex;

  const BlobBackground({super.key, required this.pageIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<BorderRadius> blobShapes = [
      const BorderRadius.only(
        topLeft: Radius.circular(160),
        topRight: Radius.circular(100),
        bottomLeft: Radius.circular(100),
        bottomRight: Radius.circular(90),
      ),
      const BorderRadius.only(
        topLeft: Radius.circular(110),
        topRight: Radius.circular(150),
        bottomLeft: Radius.circular(140),
        bottomRight: Radius.circular(100),
      ),
      const BorderRadius.only(
        topLeft: Radius.circular(100),
        topRight: Radius.circular(170),
        bottomLeft: Radius.circular(120),
        bottomRight: Radius.circular(110),
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      height: context.heightPercent(0.5),
      width: context.widthPercent(0.9),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(30),
        borderRadius: blobShapes[pageIndex],
      ),
    );
  }
}