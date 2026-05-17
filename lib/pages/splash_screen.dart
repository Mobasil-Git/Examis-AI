import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter (blur)
import 'package:examis_ai/layout/master_layout.dart';
import 'package:examis_ai/pages/auth/login_page.dart';
import 'package:examis_ai/pages/dashboard_page.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Animation Triggers
  bool _isLogoVisible = false;
  bool _isLogoShifted = false;
  bool _areIconsVisible = false;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // 1. Wait, then pop the logo in
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isLogoVisible = true);

    // 👇 CHANGED: Increased to 1400ms so the logo has time to finish its slow pop
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _isLogoShifted = true);

    // 3. Let the text settle, then gracefully fade in the floating PNGs
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _areIconsVisible = true);

    // 4. The Smart Gatekeeper
    await _checkStatusAndRoute();
  }

  Future<void> _checkStatusAndRoute() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (!mounted) return;

    if (session == null) {
      _routeTo(const LoginPage());
      return;
    }

    try {
      await supabase.from('profiles').select('id').limit(1).timeout(const Duration(seconds: 4));
      _routeTo(const MasterLayout());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Slow or no internet connection. Please check your network."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      _routeTo(const MasterLayout());
    }
  }

  void _routeTo(Widget nextScreen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1200),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final centerX = screenWidth / 2;
    final centerY = context.screenHeight / 2;

    return Scaffold(
      backgroundColor: context.background,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- THE FLOATING PNGs (Background Layer) ---
              // Notice we mix sizes, opacities, and BLUR to create a 3D depth of field

              // Top Left (Distant - Blurry & Small)
              _buildIconAnchor(
                "assets/splash_screen_assets/ai-technology.png",
                left: centerX - 150, top: centerY - 160, size: 30, opacity: 0.4, blur: 1.5, delay: 0,
              ),
              // Top Right (Midground)
              _buildIconAnchor(
                "assets/splash_screen_assets/ai-assistant.png",
                left: centerX + 90, top: centerY - 130, size: 45, opacity: 0.6, blur: 0.5, delay: 500,
              ),
              // Middle Far Left (Foreground - Sharp & Large)
              _buildIconAnchor(
                "assets/splash_screen_assets/sparkling.png",
                left: centerX - 180, top: centerY - 10, size: 55, opacity: 0.8, blur: 0, delay: 1000,
              ),
              // Middle Far Right (Distant)
              _buildIconAnchor(
                "assets/splash_screen_assets/ai-technology.png",
                left: centerX + 140, top: centerY + 20, size: 35, opacity: 0.4, blur: 1.2, delay: 250,
              ),
              // Bottom Left (Midground)
              _buildIconAnchor(
                "assets/splash_screen_assets/ai-assistant.png",
                left: centerX - 130, top: centerY + 130, size: 40, opacity: 0.5, blur: 0.8, delay: 750,
              ),
              // Bottom Right (Foreground)
              _buildIconAnchor(
                "assets/splash_screen_assets/sparkling.png",
                left: centerX + 100, top: centerY + 150, size: 50, opacity: 0.7, blur: 0.2, delay: 1250,
              ),

              // --- FOREGROUND: BRANDING ---

              // The App Name
              AnimatedPositioned(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutQuint,
                left: _isLogoShifted ? centerX - 20 : centerX - 80,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _isLogoShifted ? 1.0 : 0.0,
                  child: const Text(
                    "Examis AI",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lato',
                      fontSize: 36, // Slightly larger for impact
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // The Main Logo
              // The Main Logo
              AnimatedPositioned(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutQuint,
                left: _isLogoShifted ? centerX - 125 : centerX - 50,
                child: AnimatedScale(
                  // 👇 CHANGED: Increased duration to 1500ms
                  duration: const Duration(milliseconds: 1500),
                  // 👇 CHANGED: Swapped to easeOutBack for a slow, luxurious settle
                  curve: Curves.easeOutBack,
                  scale: _isLogoVisible ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 25,
                            spreadRadius: 5,
                          )
                        ]
                    ),
                    child: Image.asset(
                      "assets/splash_screen_assets/ExamisAI.png",
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Wrapper to handle the entrance of the background elements
  Widget _buildIconAnchor(
      String assetPath, {
        required double left,
        required double top,
        required double size,
        required double opacity,
        required double blur,
        required int delay, // Used to stagger their physics
      }) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOut,
        opacity: _areIconsVisible ? opacity : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutBack,
          scale: _areIconsVisible ? 1.0 : 0.5,
          child: StudioGradeFloatingIcon(
            assetPath: assetPath,
            size: size,
            blur: blur,
            delayMilliseconds: delay,
          ),
        ),
      ),
    );
  }
}

// --- NEW Custom Widget for True 60fps Organic Physics ---
class StudioGradeFloatingIcon extends StatefulWidget {
  final String assetPath;
  final double size;
  final double blur;
  final int delayMilliseconds;

  const StudioGradeFloatingIcon({
    super.key,
    required this.assetPath,
    required this.size,
    required this.blur,
    required this.delayMilliseconds,
  });

  @override
  State<StudioGradeFloatingIcon> createState() => _StudioGradeFloatingIconState();
}

class _StudioGradeFloatingIconState extends State<StudioGradeFloatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final math.Random _random = math.Random();

  // Random multipliers so every icon moves uniquely
  late double _verticalMulti;
  late double _rotationMulti;

  @override
  void initState() {
    super.initState();

    // Randomize movement characteristics for organic feel
    _verticalMulti = (_random.nextDouble() * 15) + 10; // Bob up/down 10-25 pixels
    _rotationMulti = (_random.nextDouble() * 0.1) - 0.05; // Slight tilt

    // Slow, luxurious 4-second breathing loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);

    // Stagger the start time so they don't move in unison
    Future.delayed(Duration(milliseconds: widget.delayMilliseconds), () {
      if (mounted) {
        _controller.repeat(reverse: true); // Yo-yo effect
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
          // Translate Y creates the gentle bobbing motion
            ..translate(0.0, _animation.value * _verticalMulti)
          // Subtle rotation brings the asset to life
            ..rotateZ(_animation.value * _rotationMulti),
          child: child,
        );
      },
      child: widget.blur > 0
          ? ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: _buildImage(),
      )
          : _buildImage(), // Skip the blur filter entirely if blur is 0 for performance
    );
  }

  Widget _buildImage() {
    return Image.asset(
      widget.assetPath,
      width: widget.size,
      height: widget.size,
      // Prevents pixelation on scaled assets
      filterQuality: FilterQuality.high,
    );
  }
}