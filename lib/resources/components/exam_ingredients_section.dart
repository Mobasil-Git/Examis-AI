import 'package:examisai/view_models/assessment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/responsive_ui.dart';

class ExamIngredientsSection extends ConsumerWidget {
  const ExamIngredientsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "Step 1: Exam Ingredients",
            style: TextStyle(
              color: colorScheme.primary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: context.isMobile ? 22 : 26,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "What types of questions do you want to include in this paper? Select your ingredients and decide if AI should randomize them.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 14 : 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.04)),

          _buildIngredientCard(
            context,
            "Multiple Choice Questions",
            state.wantsMCQs,
            state.randomMCQs,
            (v) => notifier.toggleIngredient('mcq', v),
            (v) => notifier.toggleRandomIngredient('mcq', v),
            colorScheme,
          ),
          _buildIngredientCard(
            context,
            "Fill in the Blanks",
            state.wantsFillBlanks,
            state.randomFillBlanks,
            (v) => notifier.toggleIngredient('fib', v),
            (v) => notifier.toggleRandomIngredient('fib', v),
            colorScheme,
          ),
          _buildIngredientCard(
            context,
            "Short Questions",
            state.wantsShortQs,
            state.randomShortQs,
            (v) => notifier.toggleIngredient('short', v),
            (v) => notifier.toggleRandomIngredient('short', v),
            colorScheme,
          ),
          _buildIngredientCard(
            context,
            "Long / Essay Questions",
            state.wantsLongQs,
            state.randomLongQs,
            (v) => notifier.toggleIngredient('long', v),
            (v) => notifier.toggleRandomIngredient('long', v),
            colorScheme,
          ),

          Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
            child: Material(
              color: state.wantsCustomQuestions
                  ? colorScheme.primary.withAlpha(20)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.hardEdge,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.widthPercent(0.04),
                  vertical: context.heightPercent(0.005),
                ),
                activeColor: colorScheme.primary,
                title: Text(
                  "Custom Questions",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: state.wantsCustomQuestions
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: context.isMobile ? 15 : 17,
                    color: state.wantsCustomQuestions
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  "Write explicit prompts and build multi-part (a, b) sub-questions.",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: state.wantsCustomQuestions,
                onChanged: (v) => notifier.toggleIngredient('custom', v),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
            child: Material(
              color: state.wantsScenariosOrCode
                  ? colorScheme.primary.withAlpha(20)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.hardEdge,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.widthPercent(0.04),
                  vertical: context.heightPercent(0.005),
                ),
                activeColor: colorScheme.primary,
                title: Text(
                  "Scenarios & Code Based",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: state.wantsScenariosOrCode
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: context.isMobile ? 15 : 17,
                    color: state.wantsScenariosOrCode
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  "Let AI generate complex case studies or code snippets.",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: state.wantsScenariosOrCode,
                onChanged: (v) => notifier.toggleIngredient('scenario', v),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
            child: Material(
              color: state.wantsDiagrams
                  ? colorScheme.primary.withAlpha(20)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.hardEdge,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.widthPercent(0.04),
                  vertical: context.heightPercent(0.005),
                ),
                activeColor: colorScheme.primary,
                title: Text(
                  "Diagrams & Visuals",
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontWeight: state.wantsDiagrams
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: context.isMobile ? 15 : 17,
                    color: state.wantsDiagrams
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                value: state.wantsDiagrams,
                onChanged: (v) => notifier.toggleIngredient('diagram', v),
              ),
            ),
          ),
          SizedBox(height: context.heightPercent(0.04)),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(
    BuildContext context,
    String title,
    bool isSelected,
    bool isRandom,
    ValueChanged<bool?> onSelected,
    ValueChanged<bool?> onRandomChanged,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withAlpha(20)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.widthPercent(0.04),
                vertical: context.heightPercent(0.005),
              ),
              activeColor: colorScheme.primary,
              title: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Lato',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: context.isMobile ? 15 : 17,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              value: isSelected,
              onChanged: onSelected,
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(
                  left: context.widthPercent(0.12),
                  right: context.widthPercent(0.04),
                  bottom: context.heightPercent(0.015),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: isRandom,
                        onChanged: onRandomChanged,
                        activeColor: colorScheme.secondary,
                      ),
                    ),
                    SizedBox(width: context.widthPercent(0.03)),
                    Expanded(
                      child: Text(
                        "Randomize across active CLOs",
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
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
