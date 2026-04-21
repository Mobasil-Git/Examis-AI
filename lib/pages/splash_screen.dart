import 'dart:math' as math;
import 'dart:async'; // Required for the Timer
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
    // 1. Wait, then pop the logo in smoothly
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLogoVisible = true);

    // 2. Wait for pop, then slide logo left & reveal text slowly
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isLogoShifted = true);

    // 3. Wait for slide, then pop the 6 surrounding icons
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _areIconsVisible = true);

    // 4. THE UPGRADE: Instead of blindly waiting 3.5 seconds,
    // we instantly check the internet and route the user!
    await _checkStatusAndRoute();
  }

  // --- THE NEW SMART GATEKEEPER ---
  Future<void> _checkStatusAndRoute() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (!mounted) return;

    // If they aren't logged in, instantly send them to the login page
    if (session == null) {
      _routeTo(const LoginPage());
      return;
    }

    // User IS logged in locally. Let's verify they have internet
    // by doing a lightning-fast "ping" to Supabase.
    try {
      // Timeout after 4 seconds if they are on a terrible connection or offline
      await supabase.from('profiles').select('id').limit(1).timeout(const Duration(seconds: 4));

      // Success! Internet is working.
      _routeTo(const DashboardPage());
    } catch (e) {
      // Fails if offline or timed out!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Slow or no internet connection. Please check your network."),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      // Let them into the dashboard anyway so they aren't trapped!
      _routeTo(const DashboardPage());
    }
  }

  void _routeTo(Widget nextScreen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1000), // Smooth fade out
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- The App Name (Reveals behind the logo) ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              left: _isLogoShifted ? centerX - 20 : centerX - 80,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: _isLogoShifted ? 1.0 : 0.0,
                child: const Text(
                  "Examis AI",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Lato',
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // --- The Main Logo ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              left: _isLogoShifted ? centerX - 120 : centerX - 45,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                scale: _isLogoVisible ? 1.0 : 0.0,
                child: Image.asset(
                  "assets/splash_screen_assets/ExamisAI.png",
                  width: 90,
                  height: 90,
                ),
              ),
            ),

            _buildIconAnchor(
              "assets/splash_screen_assets/ai-technology.png",
              left: centerX - 140,
              top: centerY - 150,
            ),

            // Top Right
            _buildIconAnchor(
              "assets/splash_screen_assets/ai-assistant.png",
              left: centerX + 100,
              top: centerY - 120,
            ),

            // Middle Far Left
            _buildIconAnchor(
              "assets/splash_screen_assets/sparkling.png",
              left: centerX - 180,
              top: centerY - 20,
            ),

            // Middle Far Right
            _buildIconAnchor(
              "assets/splash_screen_assets/ai-technology.png",
              left: centerX + 140,
              top: centerY + 10,
            ),

            // Bottom Left
            _buildIconAnchor(
              "assets/splash_screen_assets/ai-assistant.png",
              left: centerX - 120,
              top: centerY + 120,
            ),

            // Bottom Right
            _buildIconAnchor(
              "assets/splash_screen_assets/sparkling.png",
              left: centerX + 80,
              top: centerY + 140,
            ),
          ],
        ),
      ),
    );
  }

  // Wrapper to handle the pop-in animation
  Widget _buildIconAnchor(
    String assetPath, {
    required double left,
    required double top,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        scale: _areIconsVisible ? 1.0 : 0.0,
        child: RandomFloatingIcon(assetPath: assetPath),
      ),
    );
  }
}

// --- Custom Widget for Independent, Random Organic Floating ---
class RandomFloatingIcon extends StatefulWidget {
  final String assetPath;

  const RandomFloatingIcon({super.key, required this.assetPath});

  @override
  State<RandomFloatingIcon> createState() => _RandomFloatingIconState();
}

class _RandomFloatingIconState extends State<RandomFloatingIcon> {
  double _offsetX = 0;
  double _offsetY = 0;
  late Timer _timer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Every 2 seconds, pick a new random location to drift towards
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // Generates a random number between -20 and 20 pixels.
          // This keeps the drift tight enough that it will NEVER hit the logo.
          _offsetX = (_random.nextDouble() - 0.5) * 40;
          _offsetY = (_random.nextDouble() - 0.5) * 40;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Always clean up timers!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // 2 seconds exactly matches the timer, creating a continuous, never-ending glide
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOutSine,
      // Sine curve makes the acceleration/deceleration feel organic
      transform: Matrix4.translationValues(_offsetX, _offsetY, 0),
      child: Image.asset(widget.assetPath, width: 40, height: 40),
    );
  }
}
