import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/assessment_view_model.dart';
import '../../utils/responsive_ui.dart';

class ExamIngredientsSection extends StatelessWidget {
  const ExamIngredientsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(context.widthPercent(0.05)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_rounded, color: colorScheme.primary),
                  SizedBox(width: context.widthPercent(0.03)),
                  Text(
                    "Exam Ingredients",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 16 : 18,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.widthPercent(0.03),
                  vertical: context.heightPercent(0.005),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: colorScheme.primary.withAlpha(35),
                ),
                child: Center(
                  child: Text(
                    "Step 2",
                    style: TextStyle(
                      fontFamily: "Lato",
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "What types of questions do you want to include in this paper?",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 13 : 15,
            ),
          ),
          SizedBox(height: context.heightPercent(0.02)),

          _buildIngredientCard(context, "Multiple Choice Questions", vm.wantsMCQs, vm.randomMCQs, (v) => vm.toggleIngredient('mcq', v), (v) => vm.toggleRandomIngredient('mcq', v), colorScheme),
          _buildIngredientCard(context, "Fill in the Blanks", vm.wantsFillBlanks, vm.randomFillBlanks, (v) => vm.toggleIngredient('fib', v), (v) => vm.toggleRandomIngredient('fib', v), colorScheme),
          _buildIngredientCard(context, "Short Questions", vm.wantsShortQs, vm.randomShortQs, (v) => vm.toggleIngredient('short', v), (v) => vm.toggleRandomIngredient('short', v), colorScheme),
          _buildIngredientCard(context, "Long / Essay Questions", vm.wantsLongQs, vm.randomLongQs, (v) => vm.toggleIngredient('long', v), (v) => vm.toggleRandomIngredient('long', v), colorScheme),

          // FIX: Scenarios now act like Diagrams (No "Randomize" toggle)
          Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(0.01)),
            child: Material(
              color: vm.wantsScenariosOrCode ? colorScheme.primary.withAlpha(15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.hardEdge,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.02)),
                visualDensity: VisualDensity.compact,
                activeColor: colorScheme.primary,
                title: Text(
                  "Scenario or Code Based",
                  style: TextStyle(fontFamily: 'Lato', fontWeight: vm.wantsScenariosOrCode ? FontWeight.bold : FontWeight.w500, fontSize: context.isMobile ? 14 : 15, color: vm.wantsScenariosOrCode ? colorScheme.primary : colorScheme.onSurface),
                ),
                value: vm.wantsScenariosOrCode,
                onChanged: (v) => vm.toggleIngredient('scenario', v),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: context.heightPercent(0.01)),
            child: Material(
              color: vm.wantsDiagrams ? colorScheme.primary.withAlpha(15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.hardEdge,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.02)),
                visualDensity: VisualDensity.compact,
                activeColor: colorScheme.primary,
                title: Text(
                  "Diagrams & Visuals",
                  style: TextStyle(fontFamily: 'Lato', fontWeight: vm.wantsDiagrams ? FontWeight.bold : FontWeight.w500, fontSize: context.isMobile ? 14 : 15, color: vm.wantsDiagrams ? colorScheme.primary : colorScheme.onSurface),
                ),
                value: vm.wantsDiagrams,
                onChanged: (v) => vm.toggleIngredient('diagram', v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(BuildContext context, String title, bool isSelected, bool isRandom, ValueChanged<bool?> onSelected, ValueChanged<bool?> onRandomChanged, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.01)),
      child: Material(
        color: isSelected ? colorScheme.primary.withAlpha(15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.02)),
              visualDensity: VisualDensity.compact,
              activeColor: colorScheme.primary,
              title: Text(title, style: TextStyle(fontFamily: 'Lato', fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: context.isMobile ? 14 : 15, color: isSelected ? colorScheme.primary : colorScheme.onSurface)),
              value: isSelected,
              onChanged: onSelected,
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(left: context.widthPercent(0.12), right: context.widthPercent(0.04), bottom: context.heightPercent(0.01)),
                child: Row(
                  children: [
                    SizedBox(height: 24, width: 24, child: Checkbox(value: isRandom, onChanged: onRandomChanged, activeColor: colorScheme.secondary)),
                    SizedBox(width: context.widthPercent(0.02)),
                    Expanded(child: Text("Randomize across CLOs", style: TextStyle(fontFamily: 'Lato', fontSize: 13, color: colorScheme.onSurfaceVariant))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}