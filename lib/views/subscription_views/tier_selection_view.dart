import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/shared_pref_manager.dart';
import '../../view_models/auth_view_model.dart';
import '../../utils/responsive_ui.dart';
import '../../utils/routes/route_names.dart';

class TierSelectionView extends StatelessWidget {
  const TierSelectionView({super.key});

  void _handleSelection(BuildContext context, String tier) async {
    await SharedPrefManager().completeTierSelection();
    if (context.mounted) {
      await context.read<AuthViewModel>().updateTier(tier);
      if (tier == 'free') {
        Navigator.pushReplacementNamed(context, RouteNames.byokSettings);
      } else {
        // Future Integration: Add Stripe/RevenueCat logic here
        Navigator.pushReplacementNamed(context, RouteNames.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Upgrade to Premium",
          style: TextStyle(fontFamily: 'Lato'),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.widthPercent(0.06)),
          child: Column(
            children: [
              Text(
                "Unlock the full power of AI-driven assessments",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: context.heightPercent(0.04)),

              _buildTierCard(
                context,
                theme,
                "Free",
                "\$0 / month",
                ["5 assessments/mo", "Basic AI generation"],
                "Continue Free",
                () => _handleSelection(context, 'free'),
                false,
              ),
              SizedBox(height: context.heightPercent(0.03)),

              _buildTierCard(
                context,
                theme,
                "Premium",
                "\$19 / month",
                [
                  "Unlimited assessments",
                  "Advanced AI (Theory & Numerical)",
                  "Cloud backup",
                  "Priority support",
                ],
                "Upgrade Now",
                () => _handleSelection(context, 'premium'),
                true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    ThemeData theme,
    String title,
    String price,
    List<String> features,
    String btnText,
    VoidCallback onTap,
    bool isPremium,
  ) {
    return Container(
      padding: EdgeInsets.all(context.widthPercent(0.05)),
      decoration: BoxDecoration(
        color: isPremium
            ? theme.colorScheme.primary.withAlpha(20)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withAlpha(50),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Lato',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            price,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: context.heightPercent(0.02)),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f, style: const TextStyle(fontFamily: 'Lato')),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.heightPercent(0.02)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                btnText,
                style: TextStyle(
                  color: isPremium ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
