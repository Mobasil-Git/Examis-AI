import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'animated_exam_type_selector.dart';
import 'universal_text_field.dart';
import '../../views/course_views/course_catalog_view.dart';
import '../../views/assessment_views/assessment_preview_view.dart';
import '../../view_models/assessment_view_model.dart';
import '../../utils/responsive_ui.dart';

class CloInputSection extends StatelessWidget {
  const CloInputSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. COURSE HEADER & CLO MATRIX ---
        Container(
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
                      Icon(Icons.menu_book_rounded, color: colorScheme.primary),
                      SizedBox(width: context.widthPercent(0.03)),
                      Text(
                        "Course & Configuration",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 16 : 18,
                        ),
                      ),
                    ],
                  ),
                  if (vm.selectedCourseCode != null)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CourseCatalogView(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Change",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: context.heightPercent(0.02)),
              if (vm.selectedCourseCode != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.widthPercent(0.03)),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withAlpha(50),
                    ),
                  ),
                  child: Text(
                    "${vm.selectedCourseCode}: ${vm.selectedCourseTitle}",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 15 : 17,
                    ),
                  ),
                ),
                SizedBox(height: context.heightPercent(0.03)),
                AnimatedExamTypeSelector(
                  hasPractical: vm.hasPractical,
                  onTypeSelected: (type) =>
                      context.read<AssessmentViewModel>().setExamType(type),
                ),
                SizedBox(height: context.heightPercent(0.02)),

                if (vm.selectedExamType == 'Practical') ...[
                  SizedBox(height: context.heightPercent(0.03)),
                  const PracticalBreakdownDashboard(),
                ] else ...[
                  SizedBox(height: context.heightPercent(0.03)),
                  Text(
                    "Matrix Configuration",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: context.heightPercent(0.015)),

                  ...vm.importedCLOs.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> clo = entry.value;
                    bool isSelected = clo['isSelected'] ?? true;

                    return Container(
                      margin: EdgeInsets.only(
                        bottom: context.heightPercent(0.015),
                      ),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary.withAlpha(50)
                              : colorScheme.outline.withAlpha(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              activeColor: colorScheme.primary,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: context.widthPercent(0.03),
                                vertical: context.heightPercent(0.005),
                              ),
                              title: Text(
                                "CLO ${index + 1} (BT: ${clo['bt_level']})",
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.isMobile ? 14 : 15,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                clo['description'] ?? "",
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: context.isMobile ? 12 : 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (bool? value) => context
                                  .read<AssessmentViewModel>()
                                  .toggleCloSelection(index, value),
                            ),
                          ),
                          if (isSelected)
                            Padding(
                              padding: EdgeInsets.only(
                                left: context.widthPercent(0.04),
                                right: context.widthPercent(0.04),
                                bottom: context.heightPercent(0.02),
                              ),
                              child: Column(
                                children: [
                                  if (vm.wantsMCQs && !vm.randomMCQs)
                                    _buildMatrixRow(
                                      context,
                                      "MCQs",
                                      clo['mcq_qty'],
                                      clo['mcq_marks'],
                                      colorScheme,
                                    ),
                                  if (vm.wantsFillBlanks &&
                                      !vm.randomFillBlanks)
                                    _buildMatrixRow(
                                      context,
                                      "Fill Blanks",
                                      clo['fib_qty'],
                                      clo['fib_marks'],
                                      colorScheme,
                                    ),
                                  if (vm.wantsShortQs && !vm.randomShortQs)
                                    _buildMatrixRow(
                                      context,
                                      "Short Qs",
                                      clo['short_qty'],
                                      clo['short_marks'],
                                      colorScheme,
                                    ),
                                  if (vm.wantsLongQs && !vm.randomLongQs)
                                    _buildMatrixRow(
                                      context,
                                      "Long Qs",
                                      clo['long_qty'],
                                      clo['long_marks'],
                                      colorScheme,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: context.heightPercent(0.06),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CourseCatalogView(),
                      ),
                    ),
                    icon: Icon(Icons.search, color: colorScheme.primary),
                    label: Text(
                      "Search Course Catalog",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 15 : 17,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: colorScheme.primary.withAlpha(100),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // --- 2. GLOBAL / RANDOM SECTION ---
        if (vm.selectedCourseCode != null &&
            (vm.randomMCQs ||
                vm.randomFillBlanks ||
                vm.randomShortQs ||
                vm.randomLongQs)) ...[
          SizedBox(height: context.heightPercent(0.02)),
          Container(
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
                  children: [
                    Icon(Icons.shuffle_rounded, color: colorScheme.secondary),
                    SizedBox(width: context.widthPercent(0.03)),
                    Text(
                      "Randomized Distribution",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 16 : 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.heightPercent(0.01)),
                Text(
                  "AI will randomly assign these across all active CLOs.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.03)),
                if (vm.randomMCQs)
                  _buildMatrixRow(
                    context,
                    "MCQs",
                    vm.globalMcqQtyCtrl,
                    vm.globalMcqMarksCtrl,
                    colorScheme,
                  ),
                if (vm.randomFillBlanks)
                  _buildMatrixRow(
                    context,
                    "Fill Blanks",
                    vm.globalFibQtyCtrl,
                    vm.globalFibMarksCtrl,
                    colorScheme,
                  ),
                if (vm.randomShortQs)
                  _buildMatrixRow(
                    context,
                    "Short Qs",
                    vm.globalShortQtyCtrl,
                    vm.globalShortMarksCtrl,
                    colorScheme,
                  ),
                if (vm.randomLongQs)
                  _buildMatrixRow(
                    context,
                    "Long Qs",
                    vm.globalLongQtyCtrl,
                    vm.globalLongMarksCtrl,
                    colorScheme,
                  ),
              ],
            ),
          ),
        ],

        // --- 3. ADVANCED QUESTION BUILDER (SCENARIOS/CODE/SUB-PARTS) ---
        if (vm.selectedCourseCode != null && vm.wantsScenariosOrCode) ...[
          SizedBox(height: context.heightPercent(0.02)),
          Container(
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
                  children: [
                    Icon(
                      Icons.account_tree_rounded,
                      color: colorScheme.primary,
                    ),
                    SizedBox(width: context.widthPercent(0.03)),
                    Text(
                      "Advanced Question Builder",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 16 : 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.heightPercent(0.01)),
                Text(
                  "Build complex case studies, code analysis, or multi-part questions.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'Lato',
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: context.heightPercent(0.02)),
                Material(
                  color: Colors.transparent,
                  child: Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        "Auto-Generate Context",
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        "AI invents the scenario based on your hints",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'Lato',
                          fontSize: 12,
                        ),
                      ),
                      value: vm.letAIGenerateScenario,
                      onChanged: vm.toggleAIGenerateScenario,
                      activeColor: colorScheme.primary,
                    ),
                  ),
                ),

                ...vm.advancedQuestions.asMap().entries.map((entry) {
                  int qIndex = entry.key;
                  var qState = entry.value;
                  bool isCodeMode = qState.type == 'Code';
                  bool hasSubParts = qState.subParts.isNotEmpty;

                  return Container(
                    margin: EdgeInsets.only(top: context.heightPercent(0.015)),
                    padding: EdgeInsets.all(context.widthPercent(0.03)),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (vm.letAIGenerateScenario)
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'Scenario',
                                    label: Text('Scenario'),
                                  ),
                                  ButtonSegment(
                                    value: 'Code',
                                    label: Text('Code'),
                                  ),
                                ],
                                selected: {qState.type},
                                onSelectionChanged:
                                    (Set<String> newSelection) =>
                                        vm.updateAdvancedQuestionType(
                                          qIndex,
                                          newSelection.first,
                                        ),
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  selectedForegroundColor: Colors.white,
                                  selectedBackgroundColor: colorScheme.primary,
                                ),
                              )
                            else
                              Text(
                                "Exact Content ${qIndex + 1}",
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            if (vm.advancedQuestions.length > 1)
                              IconButton(
                                icon: Icon(
                                  Icons.remove_circle,
                                  color: colorScheme.error.withAlpha(200),
                                ),
                                onPressed: () =>
                                    vm.removeAdvancedQuestion(qIndex),
                              ),
                          ],
                        ),
                        SizedBox(height: context.heightPercent(0.015)),
                        _buildCloDropdown(
                          context,
                          vm,
                          qState.targetClo,
                          (val) => vm.updateAdvancedQuestionClo(qIndex, val),
                          colorScheme,
                        ),
                        SizedBox(height: context.heightPercent(0.015)),
                        if (vm.letAIGenerateScenario && isCodeMode) ...[
                          UniversalTextField(
                            controller: qState.langCtrl,
                            labelText: "Programming Language",
                          ),
                          SizedBox(height: context.heightPercent(0.015)),
                        ],

                        // Main Question / Context Hint
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: UniversalTextField(
                                controller: qState.textCtrl,
                                labelText: vm.letAIGenerateScenario
                                    ? "Main Context / Hint"
                                    : "Paste snippet",
                                maxLines: vm.letAIGenerateScenario ? 2 : 4,
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

                        // Sub-Parts List
                        if (hasSubParts) ...[
                          SizedBox(height: context.heightPercent(0.015)),
                          Container(
                            padding: EdgeInsets.all(context.widthPercent(0.02)),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sub-Questions",
                                  style: TextStyle(
                                    fontFamily: 'Lato',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: context.heightPercent(0.01)),
                                ...qState.subParts.asMap().entries.map((
                                  spEntry,
                                ) {
                                  int spIndex = spEntry.key;
                                  var spState = spEntry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: context.heightPercent(0.01),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "(${String.fromCharCode(97 + spIndex)})",
                                          style: TextStyle(
                                            fontFamily: 'Lato',
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        SizedBox(
                                          width: context.widthPercent(0.02),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: UniversalTextField(
                                            controller: spState.hintCtrl,
                                            labelText: "Question Hint",
                                            maxLines: 1,
                                          ),
                                        ),
                                        SizedBox(
                                          width: context.widthPercent(0.02),
                                        ),
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
                                            Icons.close,
                                            size: 16,
                                            color: colorScheme.error,
                                          ),
                                          onPressed: () =>
                                              vm.removeSubPartFromQuestion(
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
                            onPressed: () => vm.addSubPartToQuestion(qIndex),
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
                SizedBox(height: context.heightPercent(0.015)),
                OutlinedButton.icon(
                  onPressed: vm.addAdvancedQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Another Question"),
                ),
              ],
            ),
          ),
        ],

        // --- 4. DIAGRAMS BUILDER ---
        if (vm.selectedCourseCode != null && vm.wantsDiagrams) ...[
          SizedBox(height: context.heightPercent(0.02)),
          Container(
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
                  children: [
                    Icon(Icons.image_rounded, color: colorScheme.primary),
                    SizedBox(width: context.widthPercent(0.03)),
                    Text(
                      "Diagrams & Visuals",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 16 : 18,
                      ),
                    ),
                  ],
                ),
                ...vm.diagramTextControllers.asMap().entries.map((entry) {
                  int index = entry.key;
                  File? imageFile = vm.diagramImages[index];
                  return Container(
                    margin: EdgeInsets.only(top: context.heightPercent(0.015)),
                    padding: EdgeInsets.all(context.widthPercent(0.03)),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(50),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Visual Question ${index + 1}",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: colorScheme.error.withAlpha(200),
                              ),
                              onPressed: () => vm.removeDiagramQuestion(index),
                            ),
                          ],
                        ),
                        _buildCloDropdown(
                          context,
                          vm,
                          vm.diagramTargetCLOs[index],
                          (val) => vm.updateDiagramClo(index, val),
                          colorScheme,
                        ),
                        SizedBox(height: context.heightPercent(0.015)),
                        GestureDetector(
                          onTap: () =>
                              vm.pickDiagramImage(index, ImageSource.gallery),
                          child: Container(
                            height: context.heightPercent(0.12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.primary.withAlpha(50),
                              ),
                            ),
                            child: imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      imageFile,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        color: colorScheme.primary,
                                        size: 30,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Tap to select image",
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: context.heightPercent(0.015)),
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
                SizedBox(height: context.heightPercent(0.015)),
                OutlinedButton.icon(
                  onPressed: vm.addDiagramQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add Image"),
                ),
              ],
            ),
          ),
        ],

        // --- 5. BOTTOM VALIDATOR & GENERATE BUTTON ---
        if (vm.selectedCourseCode != null) ...[
          SizedBox(height: context.heightPercent(0.03)),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.widthPercent(0.05),
                vertical: context.heightPercent(0.01),
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withAlpha(50)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.track_changes_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: context.widthPercent(0.02)),
                  Text(
                    "Target: ${vm.currentTargetMarks} Marks",
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.bold,
                      fontSize: context.isMobile ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.heightPercent(0.02)),

          Consumer<AssessmentViewModel>(
            builder: (context, vm, child) {
              final int currentMarks = vm.currentConfiguredMarks;
              final int targetMarks = vm.currentTargetMarks;
              final bool isCourseImported =
                  vm.selectedCourseCode != null && targetMarks > 0;
              final bool hasFiles = vm.selectedFiles.isNotEmpty;
              final bool hasSelectedCLOs =
                  !isCourseImported ||
                  vm.importedCLOs.any((clo) => clo['isSelected'] == true);

              final bool isExactMatch = isCourseImported
                  ? (currentMarks == targetMarks)
                  : (currentMarks > 0);
              final bool isOverLimit = isCourseImported
                  ? currentMarks > targetMarks
                  : false;
              final bool isUnderLimit = isCourseImported
                  ? (currentMarks < targetMarks && currentMarks > 0)
                  : false;

              final bool disableButton =
                  vm.isLoading ||
                  currentMarks == 0 ||
                  !isExactMatch ||
                  !hasFiles ||
                  !hasSelectedCLOs;

              Color counterColor = colorScheme.onSurfaceVariant;
              String feedbackText = "";

              if (!hasFiles) {
                counterColor = Colors.orange;
                feedbackText = "Action Required: Upload curriculum notes.";
              } else if (isCourseImported && !hasSelectedCLOs) {
                counterColor = Colors.orange;
                feedbackText = "Action Required: Select at least one CLO.";
              } else if (currentMarks == 0) {
                counterColor = Colors.orange;
                feedbackText = "Action Required: Enter exam questions.";
              } else if (isCourseImported && isOverLimit) {
                counterColor = Colors.redAccent;
                feedbackText =
                    "Marks Exceeded: $currentMarks / $targetMarks (Remove ${currentMarks - targetMarks})";
              } else if (isCourseImported && isUnderLimit) {
                counterColor = Colors.orange;
                feedbackText =
                    "Marks Needed: $currentMarks / $targetMarks (Add ${targetMarks - currentMarks} more)";
              } else {
                counterColor = Colors.green;
                feedbackText = isCourseImported
                    ? "Perfect! Ready to generate."
                    : "Ready to generate ($currentMarks marks).";
              }

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.widthPercent(0.04),
                      vertical: context.heightPercent(0.01),
                    ),
                    margin: EdgeInsets.only(
                      bottom: context.heightPercent(0.02),
                    ),
                    decoration: BoxDecoration(
                      color: counterColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: counterColor.withAlpha(80)),
                    ),
                    child: Text(
                      feedbackText,
                      style: TextStyle(
                        color: counterColor,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        fontSize: context.isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: disableButton
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              await vm.triggerGeneration(context);
                              if (vm.generatedAssessment != null &&
                                  context.mounted) {
                                // Logic for navigation added in Step 5
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: context.heightPercent(0.065),
                        width: context.widthPercent(0.45),
                        decoration: BoxDecoration(
                          color: disableButton
                              ? theme.scaffoldBackgroundColor.withAlpha(400)
                              : colorScheme.primary,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: disableButton
                                ? colorScheme.outline.withAlpha(50)
                                : colorScheme.primary,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: vm.isLoading
                              ? [
                                  SizedBox(
                                    height: context.heightPercent(0.03),
                                    width: context.heightPercent(0.03),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ]
                              : [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: disableButton
                                        ? colorScheme.onSurfaceVariant
                                        : Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: context.widthPercent(0.02)),
                                  Text(
                                    "Generate",
                                    style: TextStyle(
                                      color: disableButton
                                          ? colorScheme.onSurfaceVariant
                                          : Colors.white,
                                      fontFamily: 'Lato',
                                      fontWeight: FontWeight.bold,
                                      fontSize: context.isMobile ? 16 : 18,
                                    ),
                                  ),
                                ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMatrixRow(
    BuildContext context,
    String title,
    TextEditingController qtyCtrl,
    TextEditingController marksCtrl,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.heightPercent(0.015)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.only(bottom: context.heightPercent(0.012)),
              child: Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontFamily: 'Lato',
                  fontSize: context.isMobile ? 13 : 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: context.widthPercent(0.02)),
          Expanded(
            flex: 2,
            child: UniversalTextField(
              controller: qtyCtrl,
              labelText: "Qty",
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(width: context.widthPercent(0.02)),
          Expanded(
            flex: 2,
            child: UniversalTextField(
              controller: marksCtrl,
              labelText: "Marks",
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloDropdown(
    BuildContext context,
    AssessmentViewModel vm,
    String? currentValue,
    ValueChanged<String?> onChanged,
    ColorScheme colorScheme,
  ) {
    final activeCLOs = vm.importedCLOs
        .where((c) => c['isSelected'] == true)
        .toList();
    if (activeCLOs.isEmpty) return const SizedBox.shrink();

    // 1. Generate the list of currently valid (checked) CLO names
    final List<String> validCloNames = activeCLOs
        .map((c) => "CLO ${vm.importedCLOs.indexOf(c) + 1}")
        .toList();

    // 2. Defensive check: If the previously selected CLO was just unchecked, set value to null
    final String? safeValue = validCloNames.contains(currentValue)
        ? currentValue
        : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.widthPercent(0.03)),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withAlpha(50)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: safeValue,
          // FIXED: Using safeValue instead of raw currentValue
          hint: Text(
            "Select Target CLO (Optional)",
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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

// ... PracticalBreakdownDashboard remains the exact same as before ...
class PracticalBreakdownDashboard extends StatefulWidget {
  const PracticalBreakdownDashboard({super.key});

  @override
  State<PracticalBreakdownDashboard> createState() =>
      _PracticalBreakdownDashboardState();
}

class _PracticalBreakdownDashboardState
    extends State<PracticalBreakdownDashboard> {
  late TextEditingController _vivaController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AssessmentViewModel>();
    _vivaController = TextEditingController(text: vm.vivaWeightage.toString());
  }

  @override
  void dispose() {
    _vivaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AssessmentViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(context.widthPercent(0.04)),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Marks Distribution",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Lato',
              fontWeight: FontWeight.bold,
              fontSize: context.isMobile ? 13 : 15,
            ),
          ),
          SizedBox(height: context.heightPercent(0.02)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Viva / Quizzes",
                      style: TextStyle(
                        fontSize: context.isMobile ? 12 : 14,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.01)),
                    TextFormField(
                      controller: _vivaController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontFamily: 'Lato',
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.widthPercent(0.04),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withAlpha(50),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withAlpha(50),
                          ),
                        ),
                      ),
                      onChanged: (value) => context
                          .read<AssessmentViewModel>()
                          .updateVivaWeightage(value),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.widthPercent(0.04)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lab Tasks / Code",
                      style: TextStyle(
                        fontSize: context.isMobile ? 12 : 14,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: context.heightPercent(0.01)),
                    Container(
                      height: 48,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.widthPercent(0.04),
                      ),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withAlpha(30),
                        ),
                      ),
                      child: Text(
                        "${vm.labTaskWeightage}",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          fontSize: context.isMobile ? 16 : 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
