import 'package:flutter/material.dart';
import 'route_names.dart';
import '../../views/splash_view.dart';
import '../../views/onboarding_view.dart';
import '../../views/dashboard_views/master_layout_view.dart';
import '../../views/auth_views/login_view.dart';
import '../../views/auth_views/sign_up_view.dart';
import '../../views/subscription_views/tier_selection_view.dart';
import '../../views/subscription_views/byok_settings_view.dart';

class Routes {
  Routes._();

  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (context) => const SplashView());
      case RouteNames.onboarding:
        return MaterialPageRoute(builder: (context) => const OnboardingView());
      case RouteNames.home:
        return MaterialPageRoute(builder: (context) => const MasterLayoutView());
      case RouteNames.login:
        return MaterialPageRoute(builder: (context) => const LoginView());
      case RouteNames.signUp:
        return MaterialPageRoute(builder: (context) => const SignupView());
      case RouteNames.tierSelection:
        return MaterialPageRoute(builder: (context) => const TierSelectionView());
      case RouteNames.byokSettings:
        return MaterialPageRoute(builder: (context) => const BYOKSettingsView());

      case RouteNames.forgot_password:
      case RouteNames.verify_identity:
      case RouteNames.create_new_password:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('This flow is now handled by dialogs.')),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('No route available')),
          ),
        );
    }
  }
}