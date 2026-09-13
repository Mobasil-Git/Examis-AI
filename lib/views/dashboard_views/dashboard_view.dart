import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../resources/components/fade_scale_animation.dart';
import '../../resources/components/clo_input_section.dart';
import '../../resources/components/profile_section.dart';
import '../../resources/components/upload_section.dart';
import '../../resources/components/exam_ingredients_section.dart'; // NEW COMPONENT
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
    final assessmentVM = context.watch<AssessmentViewModel>();

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

                  // STEP 1: Upload Source
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04)),
                    child: const FadeScaleAnimation(delay: 950, child: UploadSection()),
                  ),
                  SizedBox(height: context.heightPercent(0.02)),

                  // STEP 2: Exam Ingredients Selection
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04)),
                    child: const FadeScaleAnimation(delay: 1100, child: ExamIngredientsSection()),
                  ),
                  SizedBox(height: context.heightPercent(0.02)),

                  // STEP 3: Course & Objectives (Only show if an ingredient is selected)
                  if (assessmentVM.hasSelectedIngredients) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04)),
                      child: const FadeScaleAnimation(delay: 1250, child: CloInputSection()),
                    ),
                    SizedBox(height: context.heightPercent(0.15)),
                  ],

                  // REMOVING THE OLD DIAGRAM AND GENERATE SECTIONS TEMPORARILY
                  // We will absorb their functions into the CLO matrix in the next step.
                  // Padding(
                  //  padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.04)),
                  //  child: const FadeScaleAnimation(delay: 1250, child: DiagramInputSection()),
                  // ),
                  // SizedBox(height: context.heightPercent(0.02)),
                  // Expanded(
                  //  child: Padding(
                  //    padding: EdgeInsets.only(left: context.widthPercent(0.04), right: context.widthPercent(0.04), bottom: context.heightPercent(0.015)),
                  //    child: const FadeScaleAnimation(delay: 1400, child: GenerateSection()),
                  //  ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}