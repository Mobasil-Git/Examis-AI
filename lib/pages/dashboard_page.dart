import 'package:examis_ai/app_animations/dashboard_animation/fade_scale_animation.dart';
import 'package:examis_ai/componenets/drawer/app_drawer.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/generate_section.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/profile_section.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/upload_section.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.background,
        drawer: AppDrawer(),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  FadeScaleAnimation(
                    delay: 800,
                    child: const ProfileSection(),
                  ),

                  SizedBox(height: context.heightPercent(0.017)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeScaleAnimation(delay: 950,child: UploadSection()),
                  ),

                  SizedBox(height: context.heightPercent(0.017)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: FadeScaleAnimation(delay: 1100,child: GenerateSection()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
