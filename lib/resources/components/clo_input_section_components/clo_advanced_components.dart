import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../view_models/assessment_view_model.dart';
import '../../../utils/responsive_ui.dart';
import '../universal_text_field.dart';

class CustomQuestionsStep extends StatelessWidget {
  const CustomQuestionsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPercent(0.06),
        vertical: context.heightPercent(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Custom Questions",
            style: TextStyle(
              color: colorScheme.primary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: context.isMobile ? 22 : 26,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "Add specific multi-part questions tied to specific CLOs.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 14 : 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),

          ...vm.customQuestions.asMap().entries.map((entry) {
            int qIndex = entry.key;
            var qState = entry.value;
            bool hasSubParts = qState.subParts.isNotEmpty;
            return Container(
              margin: EdgeInsets.only(bottom: context.heightPercent(0.025)),
              padding: EdgeInsets.all(context.widthPercent(0.04)),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: qState.targetClo == null
                      ? colorScheme.error.withAlpha(150)
                      : colorScheme.outline.withAlpha(40),
                  width: qState.targetClo == null ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Question ${qIndex + 1}",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (vm.customQuestions.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error.withAlpha(200),
                          ),
                          onPressed: () => vm.removeCustomQuestion(qIndex),
                        ),
                    ],
                  ),
                  SizedBox(height: context.heightPercent(0.01)),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        "Auto-Generate with AI",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      value: qState.useAI,
                      onChanged: (val) =>
                          vm.toggleCustomQuestionAI(qIndex, val),
                      activeColor: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.01)),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.widthPercent(0.03),
                          ),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outline.withAlpha(50),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value:
                              vm.activeSubjectiveIngredientNames.contains(
                                qState.type,
                              )
                                  ? qState.type
                                  : vm.activeSubjectiveIngredientNames.first,
                              items: vm.activeSubjectiveIngredientNames.map((
                                  name,
                                  ) {
                                return DropdownMenuItem(
                                  value: name,
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Lato',
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => vm.updateCustomQuestionType(
                                qIndex,
                                val ?? vm.activeSubjectiveIngredientNames.first,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.widthPercent(0.02)),
                      Expanded(
                        child: WizardCloDropdown(
                          vm: vm,
                          currentValue: qState.targetClo,
                          onChanged: (val) =>
                              vm.updateCustomQuestionClo(qIndex, val),
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: UniversalTextField(
                          controller: qState.textCtrl,
                          labelText: qState.useAI
                              ? "Context / Hint for AI"
                              : "Paste exact question",
                          maxLines: qState.useAI ? 2 : 3,
                        ),
                      ),
                      if (!hasSubParts) ...[
                        SizedBox(width: context.widthPercent(0.02)),
                        Expanded(
                          flex: 1,
                          child: UniversalTextField(
                            controller: qState.marksCtrl,
                            labelText: "Marks",
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasSubParts) ...[
                    SizedBox(height: context.heightPercent(0.02)),
                    Container(
                      padding: EdgeInsets.all(context.widthPercent(0.03)),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.outline.withAlpha(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sub-parts",
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: context.heightPercent(0.015)),
                          ...qState.subParts.asMap().entries.map((spEntry) {
                            int spIndex = spEntry.key;
                            var spState = spEntry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: context.heightPercent(0.015),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Text(
                                      "(${String.fromCharCode(97 + spIndex)})",
                                      style: TextStyle(
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: context.widthPercent(0.02)),
                                  // BUG FIX: Hide the hint field if useAI is true
                                  if (!qState.useAI) ...[
                                    Expanded(
                                      flex: 3,
                                      child: UniversalTextField(
                                        controller: spState.hintCtrl,
                                        labelText: "Exact text",
                                        maxLines: 1,
                                      ),
                                    ),
                                    SizedBox(width: context.widthPercent(0.02)),
                                  ],
                                  Expanded(
                                    flex: 1,
                                    child: UniversalTextField(
                                      controller: spState.marksCtrl,
                                      labelText: "Marks",
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 20,
                                      color: colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        vm.removeSubPartFromCustomQuestion(
                                          qIndex,
                                          spIndex,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: context.heightPercent(0.01)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => vm.addSubPartToCustomQuestion(qIndex),
                      icon: Icon(
                        Icons.add_task_rounded,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        "Add Sub-Part (a, b)",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: context.heightPercent(0.01)),
          Center(
            child: OutlinedButton.icon(
              onPressed: vm.addCustomQuestion,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06), vertical: context.heightPercent(0.015)),
                side: BorderSide(color: colorScheme.primary.withAlpha(100)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.add_rounded, size: 20, color: colorScheme.primary),
              label: Text("Add Another Question", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: context.heightPercent(0.04)),
        ],
      ),
    );
  }
}

class ScenariosStep extends StatelessWidget {
  const ScenariosStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPercent(0.06),
        vertical: context.heightPercent(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Scenarios & Code",
            style: TextStyle(
              color: colorScheme.primary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: context.isMobile ? 22 : 26,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "Let AI generate complete evaluations or manually paste case studies.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 14 : 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),

          ...vm.scenarioQuestions.asMap().entries.map((entry) {
            int qIndex = entry.key;
            var qState = entry.value;
            bool isCodeMode = qState.type == 'Code';
            return Container(
              margin: EdgeInsets.only(bottom: context.heightPercent(0.025)),
              padding: EdgeInsets.all(context.widthPercent(0.04)),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: qState.targetClo == null
                      ? colorScheme.error.withAlpha(150)
                      : colorScheme.outline.withAlpha(40),
                  width: qState.targetClo == null ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Scenario',
                            label: Text('Scenario'),
                          ),
                          ButtonSegment(value: 'Code', label: Text('Code')),
                        ],
                        selected: {qState.type},
                        onSelectionChanged: (Set<String> newSelection) =>
                            vm.updateScenarioType(qIndex, newSelection.first),
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          selectedForegroundColor: Colors.white,
                          selectedBackgroundColor: colorScheme.primary,
                        ),
                      ),
                      if (vm.scenarioQuestions.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error.withAlpha(200),
                          ),
                          onPressed: () => vm.removeScenarioQuestion(qIndex),
                        ),
                    ],
                  ),
                  SizedBox(height: context.heightPercent(0.015)),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        "Auto-Generate with AI",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      value: qState.useAI,
                      onChanged: (val) =>
                          vm.toggleScenarioAI(qIndex, val),
                      activeColor: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.01)),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.widthPercent(0.03),
                          ),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colorScheme.outline.withAlpha(50),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: qState.mergeCategory,
                              items: ['Stand-alone', 'Short Question', 'Long Question'].map((name) {
                                return DropdownMenuItem(
                                  value: name,
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'Lato',
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => vm.updateScenarioMergeCategory(
                                qIndex,
                                val ?? 'Stand-alone',
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.widthPercent(0.02)),
                      Expanded(
                        child: WizardCloDropdown(
                          vm: vm,
                          currentValue: qState.targetClo,
                          onChanged: (val) => vm.updateScenarioClo(qIndex, val),
                          colorScheme: colorScheme,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  if (isCodeMode) ...[
                    UniversalTextField(
                      controller: qState.langCtrl,
                      labelText: "Programming Language",
                    ),
                    SizedBox(height: context.heightPercent(0.02)),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: UniversalTextField(
                          controller: qState.textCtrl,
                          labelText: qState.useAI
                              ? "Hint for generation"
                              : "Paste exact text",
                          maxLines: qState.useAI ? 2 : 3,
                        ),
                      ),
                      SizedBox(width: context.widthPercent(0.02)),
                      Expanded(
                        flex: 1,
                        child: UniversalTextField(
                          controller: qState.marksCtrl,
                          labelText: "Marks",
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: context.heightPercent(0.01)),
          Center(
            child: OutlinedButton.icon(
              onPressed: vm.addScenarioQuestion,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06), vertical: context.heightPercent(0.015)),
                side: BorderSide(color: colorScheme.primary.withAlpha(100)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.add_rounded, size: 20, color: colorScheme.primary),
              label: Text("Add Another Item", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: context.heightPercent(0.04)),
        ],
      ),
    );
  }
}

class DiagramsStep extends StatelessWidget {
  const DiagramsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.widthPercent(0.06),
        vertical: context.heightPercent(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Diagrams & Visuals",
            style: TextStyle(
              color: colorScheme.primary,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w900,
              fontSize: context.isMobile ? 22 : 26,
            ),
          ),
          SizedBox(height: context.heightPercent(0.01)),
          Text(
            "Upload reference images and set diagram questions.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontSize: context.isMobile ? 14 : 16,
              height: 1.4,
            ),
          ),
          SizedBox(height: context.heightPercent(0.03)),

          ...vm.diagramTextControllers.asMap().entries.map((entry) {
            int index = entry.key;
            File? imageFile = vm.diagramImages[index];
            return Container(
              margin: EdgeInsets.only(bottom: context.heightPercent(0.025)),
              padding: EdgeInsets.all(context.widthPercent(0.04)),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: vm.diagramTargetCLOs[index] == null
                      ? colorScheme.error.withAlpha(150)
                      : colorScheme.outline.withAlpha(40),
                  width: vm.diagramTargetCLOs[index] == null ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Visual Question ${index + 1}",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (vm.diagramTextControllers.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colorScheme.error.withAlpha(200),
                          ),
                          onPressed: () => vm.removeDiagramQuestion(index),
                        ),
                    ],
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  WizardCloDropdown(
                    vm: vm,
                    currentValue: vm.diagramTargetCLOs[index],
                    onChanged: (val) => vm.updateDiagramClo(index, val),
                    colorScheme: colorScheme,
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  GestureDetector(
                    onTap: () =>
                        vm.pickDiagramImage(index, ImageSource.gallery),
                    child: Container(
                      height: context.heightPercent(0.15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withAlpha(50),
                        ),
                      ),
                      child: imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(imageFile, fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Tap to select image",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.02)),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: UniversalTextField(
                          controller: vm.diagramTextControllers[index],
                          labelText: "Question for Diagram",
                        ),
                      ),
                      SizedBox(width: context.widthPercent(0.02)),
                      Expanded(
                        flex: 1,
                        child: UniversalTextField(
                          controller: vm.diagramMarksControllers[index],
                          labelText: "Marks",
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: context.heightPercent(0.01)),
          Center(
            child: OutlinedButton.icon(
              onPressed: vm.addDiagramQuestion,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.06), vertical: context.heightPercent(0.015)),
                side: BorderSide(color: colorScheme.primary.withAlpha(100)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.add_rounded, size: 20, color: colorScheme.primary),
              label: Text("Add Another Image", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: context.heightPercent(0.04)),
        ],
      ),
    );
  }
}

class WizardCloDropdown extends StatelessWidget {
  final AssessmentViewModel vm;
  final String? currentValue;
  final ValueChanged<String?> onChanged;
  final ColorScheme colorScheme;

  const WizardCloDropdown({
    super.key,
    required this.vm,
    required this.currentValue,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final activeCLOs = vm.importedCLOs
        .where((c) => c['isSelected'] == true)
        .toList();
    if (activeCLOs.isEmpty) return const SizedBox.shrink();

    final List<String> validCloNames = activeCLOs
        .map((c) => "CLO ${vm.importedCLOs.indexOf(c) + 1}")
        .toList();
    final String? safeValue = validCloNames.contains(currentValue)
        ? currentValue
        : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.03)),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: safeValue == null
              ? colorScheme.error.withAlpha(150)
              : colorScheme.outline.withAlpha(50),
          width: safeValue == null ? 1.5 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: safeValue,
          hint: Text(
            "Target CLO (Required)",
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.error.withAlpha(200),
              fontWeight: FontWeight.bold,
            ),
          ),
          items: validCloNames.map((cloName) {
            return DropdownMenuItem(
              value: cloName,
              child: Text(
                cloName,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Lato',
                  color: colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}