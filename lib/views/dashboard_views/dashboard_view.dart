import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../resources/components/fade_scale_animation.dart';
import '../../resources/components/clo_input_section.dart';
import '../../resources/components/diagram_input_section.dart';
import '../../resources/components/generate_section.dart';
import '../../resources/components/profile_section.dart';
import '../../resources/components/upload_section.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/history_view_model.dart';
import '../../view_models/assessment_view_model.dart';
import '../../utils/responsive_ui.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Key _refreshKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentViewModel>().fetchDepartments();
      context.read<AssessmentViewModel>().fetchBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: colorScheme.primary,
        onRefresh: () async {
          await context.read<AuthViewModel>().fetchUserProfile();
          await context.read<HistoryViewModel>().loadHistory();
          await context.read<AssessmentViewModel>().clearData();

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
                  const FadeScaleAnimation(delay: 800, child: ProfileSection()),
                  SizedBox(height: context.heightPercent(0.02)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.widthPercent(0.04),
                    ),
                    child: const FadeScaleAnimation(
                      delay: 950,
                      child: UploadSection(),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.widthPercent(0.04),
                    ),
                    child: const FadeScaleAnimation(
                      delay: 1100,
                      child: CloInputSection(),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.widthPercent(0.04),
                    ),
                    child: const FadeScaleAnimation(
                      delay: 1250,
                      child: DiagramInputSection(),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: context.widthPercent(0.04),
                        right: context.widthPercent(0.04),
                        bottom: context.heightPercent(0.015),
                      ),
                      child: const FadeScaleAnimation(
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
