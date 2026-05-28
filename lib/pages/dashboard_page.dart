import 'package:examis_ai/app_animations/dashboard_animation/fade_scale_animation.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/clo_input_section.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/diagram_input_section.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/generate_section.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/profile_section.dart';
import 'package:examis_ai/componenets/main%20screen%20componenets/upload_section.dart';
import 'package:examis_ai/provider/auth_provider.dart';
import 'package:examis_ai/provider/history_provider.dart';
import 'package:examis_ai/theming/app_colors.dart';
import 'package:examis_ai/utils/responive_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/assessment_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Key _refreshKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentProvider>().fetchDepartments();
      context.read<AssessmentProvider>().fetchBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await context.read<AuthProvider>().fetchUserProfile();
          await context.read<HistoryProvider>().loadHistory();
          await context.read<AssessmentProvider>().clearData();

          setState(() {
            _refreshKey = UniqueKey();
          });
        },
        child: CustomScrollView(
          key: _refreshKey,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  FadeScaleAnimation(delay: 800, child: const ProfileSection()),

                  SizedBox(height: context.heightPercent(0.017)),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeScaleAnimation(
                      delay: 950,
                      child: UploadSection(),
                    ),
                  ),

                  SizedBox(height: context.heightPercent(0.017)),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeScaleAnimation(
                      delay: 1100,
                      child: const CloInputSection(),
                    ),
                  ),

                  SizedBox(height: context.heightPercent(0.017)),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeScaleAnimation(
                      delay: 1250,
                      child: const DiagramInputSection(),
                    ),
                  ),

                  SizedBox(height: context.heightPercent(0.017)),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 12,
                      ),
                      child: FadeScaleAnimation(
                        delay: 1400,
                        child: GenerateSection(),
                      ),
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
