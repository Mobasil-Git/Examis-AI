import 'dart:math' as math;
import 'dart:ui';
import 'package:examisai/data/local/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/responsive_ui.dart';
import '../utils/routes/route_names.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _isLogoVisible = false;
  bool _isLogoShifted = false;
  bool _areIconsVisible = false;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isLogoVisible = true);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _isLogoShifted = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _areIconsVisible = true);

    await _checkStatusAndRoute();
  }

  Future<void> _checkStatusAndRoute() async {
    if (!mounted) return;

    final isFirstLaunch = await SharedPrefManager().isFirstTimeLaunch();
    if (isFirstLaunch) {
      _routeTo(RouteNames.onboarding);
      return;
    }

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      _routeTo(RouteNames.login);
      return;
    }

    try {
      await supabase.from('profiles').select('id').limit(1).timeout(const Duration(seconds: 4));

      final hasSeenTier = await SharedPrefManager().hasSeenTierSelection();
      if (!hasSeenTier) {
        _routeTo(RouteNames.tierSelection);
      } else {
        _routeTo(RouteNames.home);
      }
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
      _routeTo(RouteNames.home);
    }
  }

  void _routeTo(String routeName) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final centerX = screenWidth / 2;
    final centerY = context.screenHeight / 2;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildIconAnchor("assets/splash_screen_assets/ai-technology.png", left: centerX - context.widthPercent(0.35), top: centerY - context.heightPercent(0.2), size: context.widthPercent(0.08), opacity: 0.4, blur: 1.5, delay: 0),
              _buildIconAnchor("assets/splash_screen_assets/ai-assistant.png", left: centerX + context.widthPercent(0.2), top: centerY - context.heightPercent(0.15), size: context.widthPercent(0.11), opacity: 0.6, blur: 0.5, delay: 500),
              _buildIconAnchor("assets/splash_screen_assets/sparkling.png", left: centerX - context.widthPercent(0.4), top: centerY - context.heightPercent(0.02), size: context.widthPercent(0.13), opacity: 0.8, blur: 0, delay: 1000),
              _buildIconAnchor("assets/splash_screen_assets/ai-technology.png", left: centerX + context.widthPercent(0.3), top: centerY + context.heightPercent(0.02), size: context.widthPercent(0.09), opacity: 0.4, blur: 1.2, delay: 250),
              _buildIconAnchor("assets/splash_screen_assets/ai-assistant.png", left: centerX - context.widthPercent(0.3), top: centerY + context.heightPercent(0.15), size: context.widthPercent(0.1), opacity: 0.5, blur: 0.8, delay: 750),
              _buildIconAnchor("assets/splash_screen_assets/sparkling.png", left: centerX + context.widthPercent(0.25), top: centerY + context.heightPercent(0.18), size: context.widthPercent(0.12), opacity: 0.7, blur: 0.2, delay: 1250),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutQuint,
                left: _isLogoShifted ? centerX - context.widthPercent(0.05) : centerX - context.widthPercent(0.2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _isLogoShifted ? 1.0 : 0.0,
                  child: Text(
                    "Examis AI",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Lato',
                      fontSize: context.isMobile ? 36 : 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutQuint,
                left: _isLogoShifted ? centerX - context.widthPercent(0.3) : centerX - context.widthPercent(0.12),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutBack,
                  scale: _isLogoVisible ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(40),
                          blurRadius: 25,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Image.asset(
                      "assets/splash_screen_assets/ExamisAI.png",
                      width: context.widthPercent(0.25),
                      height: context.widthPercent(0.25),
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

  Widget _buildIconAnchor(String assetPath, {required double left, required double top, required double size, required double opacity, required double blur, required int delay}) {
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

class StudioGradeFloatingIcon extends StatefulWidget {
  final String assetPath;
  final double size;
  final double blur;
  final int delayMilliseconds;

  const StudioGradeFloatingIcon({super.key, required this.assetPath, required this.size, required this.blur, required this.delayMilliseconds});

  @override
  State<StudioGradeFloatingIcon> createState() => _StudioGradeFloatingIconState();
}

class _StudioGradeFloatingIconState extends State<StudioGradeFloatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final math.Random _random = math.Random();

  late double _verticalMulti;
  late double _rotationMulti;

  @override
  void initState() {
    super.initState();
    _verticalMulti = (_random.nextDouble() * 15) + 10;
    _rotationMulti = (_random.nextDouble() * 0.1) - 0.05;

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);

    Future.delayed(Duration(milliseconds: widget.delayMilliseconds), () {
      if (mounted) _controller.repeat(reverse: true);
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
            ..translate(0.0, _animation.value * _verticalMulti)
            ..rotateZ(_animation.value * _rotationMulti),
          child: child,
        );
      },
      child: widget.blur > 0 ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur), child: _buildImage()) : _buildImage(),
    );
  }

  Widget _buildImage() {
    return Image.asset(widget.assetPath, width: widget.size, height: widget.size, filterQuality: FilterQuality.high);
  }
}