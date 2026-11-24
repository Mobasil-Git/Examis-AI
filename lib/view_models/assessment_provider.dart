import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'states/assessment_state.dart';
import 'auth_provider.dart';
import 'history_provider.dart';
import '../utils/theme/app_colors.dart';
import '../utils/utils.dart';

export 'states/assessment_state.dart';

class AssessmentNotifier extends Notifier<AssessmentState> {
  void _bump() => state = state.copyWith(revision: state.revision + 1);

  TextEditingController _ctrl(String text) {
    final c = TextEditingController(text: text);
    c.addListener(_bump);
    return c;
  }

  void _disposeStateControllers(AssessmentState s) {
    s.globalMcqQtyCtrl.dispose();
    s.globalMcqMarksCtrl.dispose();
    s.globalFibQtyCtrl.dispose();
    s.globalFibMarksCtrl.dispose();
    s.globalShortQtyCtrl.dispose();
    s.globalShortMarksCtrl.dispose();
    s.globalLongQtyCtrl.dispose();
    s.globalLongMarksCtrl.dispose();

    for (var clo in s.importedCLOs) {
      (clo['mcq_qty'] as TextEditingController?)?.dispose();
      (clo['mcq_marks'] as TextEditingController?)?.dispose();
      (clo['fib_qty'] as TextEditingController?)?.dispose();
      (clo['fib_marks'] as TextEditingController?)?.dispose();
      (clo['short_qty'] as TextEditingController?)?.dispose();
      (clo['short_marks'] as TextEditingController?)?.dispose();
      (clo['long_qty'] as TextEditingController?)?.dispose();
      (clo['long_marks'] as TextEditingController?)?.dispose();
    }

    for (var q in s.customQuestions) q.dispose();
    for (var sq in s.scenarioQuestions) sq.dispose();
    for (var c in s.diagramTextControllers) c.dispose();
    for (var c in s.diagramMarksControllers) c.dispose();
  }

  @override
  AssessmentState build() {
    ref.onDispose(() => _disposeStateControllers(state));

    return AssessmentState(
      globalMcqQtyCtrl: _ctrl(''),
      globalMcqMarksCtrl: _ctrl(''),
      globalFibQtyCtrl: _ctrl(''),
      globalFibMarksCtrl: _ctrl(''),
      globalShortQtyCtrl: _ctrl(''),
      globalShortMarksCtrl: _ctrl(''),
      globalLongQtyCtrl: _ctrl(''),
      globalLongMarksCtrl: _ctrl(''),
    );
  }

  void clearData() {
    _disposeStateControllers(state);
    state = build();
  }

  void loadPastAssessment(JsonMap data) {
    // Backwards compatibility: Calculate total marks dynamically for old papers
    double fallbackTotal = 0.0;
    if (data['meta_total_marks'] == null) {
      final types = ['mcqs', 'fillInTheBlanks', 'shortQuestions', 'longQuestions', 'custom_scenarios', 'diagram_questions'];
      for (var type in types) {
        if (data[type] != null && data[type] is List) {
          for (var q in data[type]) {
            fallbackTotal += (q['marks'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }

    state = state.copyWith(
      generatedAssessment: data,
      selectedCourseTitle: data['meta_course_title'] ?? "Restored Assessment",
      selectedCourseCode: data['meta_course_code'] ?? state.selectedCourseCode,
      courseCreditHours: data['meta_credit_hours'] ?? state.courseCreditHours,
      selectedDepartmentName: data['meta_department'] ?? state.selectedDepartmentName,
      selectedExamType: data['meta_exam_type'] ?? state.selectedExamType,
      currentTargetMarks: (data['meta_total_marks'] as num?)?.toDouble() ?? (fallbackTotal > 0 ? fallbackTotal : state.currentTargetMarks),
    );
  }

  double _calculateMarks(String examType, String creditHours) {
    final match = RegExp(
      r'\(\s*(\d+)\s*-\s*(\d+)\s*\)',
    ).firstMatch(creditHours);
    int theoryCredits = 3;
    int practicalCredits = 0;

    if (match != null) {
      theoryCredits = int.parse(match.group(1)!);
      practicalCredits = int.parse(match.group(2)!);
    } else {
      theoryCredits = int.tryParse(creditHours.trim()) ?? 3;
    }

    final lowerType = examType.toLowerCase();
    if (lowerType.contains('practical')) {
      return (practicalCredits * 20).toDouble();
    }

    final double totalTheoryMarks = (theoryCredits * 20).toDouble();
    if (lowerType.contains('final')) {
      return totalTheoryMarks * 0.60;
    }
    return totalTheoryMarks * 0.30;
  }

  void toggleIngredient(String type, bool? value) {
    final val = value ?? false;
    switch (type) {
      case 'mcq':
        state = state.copyWith(wantsMCQs: val);
      case 'fib':
        state = state.copyWith(wantsFillBlanks: val);
      case 'short':
        state = state.copyWith(wantsShortQs: val);
      case 'long':
        state = state.copyWith(wantsLongQs: val);
      case 'custom':
        state = state.copyWith(wantsCustomQuestions: val);
        if (val && state.customQuestions.isEmpty) addCustomQuestion();
      case 'scenario':
        state = state.copyWith(wantsScenariosOrCode: val);
        if (val && state.scenarioQuestions.isEmpty) addScenarioQuestion();
      case 'diagram':
        state = state.copyWith(wantsDiagrams: val);
        if (val && state.diagramTextControllers.isEmpty) addDiagramQuestion();
    }
  }

  void toggleRandomIngredient(String type, bool? value) {
    final val = value ?? false;
    switch (type) {
      case 'mcq':
        state = state.copyWith(randomMCQs: val);
      case 'fib':
        state = state.copyWith(randomFillBlanks: val);
      case 'short':
        state = state.copyWith(randomShortQs: val);
      case 'long':
        state = state.copyWith(randomLongQs: val);
    }
  }

  void setImportedCourse(
      String code,
      String title,
      List<JsonMap> rawClos,
      String creditHrs,
      String deptName,
      ) {
    for (var clo in state.importedCLOs) {
      (clo['mcq_qty'] as TextEditingController?)?.dispose();
      (clo['mcq_marks'] as TextEditingController?)?.dispose();
      (clo['fib_qty'] as TextEditingController?)?.dispose();
      (clo['fib_marks'] as TextEditingController?)?.dispose();
      (clo['short_qty'] as TextEditingController?)?.dispose();
      (clo['short_marks'] as TextEditingController?)?.dispose();
      (clo['long_qty'] as TextEditingController?)?.dispose();
      (clo['long_marks'] as TextEditingController?)?.dispose();
    }

    final hydratedClos = rawClos
        .map(
          (clo) => <String, dynamic>{
        ...clo,
        'isSelected': true,
        'mcq_qty': _ctrl(''),
        'mcq_marks': _ctrl(''),
        'fib_qty': _ctrl(''),
        'fib_marks': _ctrl(''),
        'short_qty': _ctrl(''),
        'short_marks': _ctrl(''),
        'long_qty': _ctrl(''),
        'long_marks': _ctrl(''),
      },
    )
        .toList();

    final hasPrac = RegExp(
      r'\(\s*\d+\s*-\s*([1-9]\d*)\s*\)',
    ).hasMatch(creditHrs);
    final activeExamType = (!hasPrac && state.selectedExamType == 'Practical')
        ? 'Mid-Term'
        : state.selectedExamType;
    final targetMarks = _calculateMarks(activeExamType, creditHrs);

    state = state.copyWith(
      selectedCourseCode: code,
      selectedCourseTitle: title,
      importedCLOs: hydratedClos,
      courseCreditHours: creditHrs,
      selectedDepartmentName: deptName,
      selectedExamType: activeExamType,
      currentTargetMarks: targetMarks,
      vivaWeightage: state.vivaWeightage.clamp(0, targetMarks.toInt()),
    );
  }

  void setExamType(String type) {
    final target = _calculateMarks(type, state.courseCreditHours);
    state = state.copyWith(
      selectedExamType: type,
      currentTargetMarks: target,
      vivaWeightage: state.vivaWeightage.clamp(0, target.toInt()),
    );
  }

  void toggleCloSelection(int index, bool? value) {
    final updated = List<JsonMap>.from(state.importedCLOs);
    updated[index] = {...updated[index], 'isSelected': value ?? false};
    state = state.copyWith(importedCLOs: updated);
  }

  void updateVivaWeightage(String value) {
    final parsed = int.tryParse(value.trim()) ?? 0;
    state = state.copyWith(
      vivaWeightage: parsed.clamp(0, state.currentTargetMarks.toInt()),
    );
  }
  // --- FILE UPLOADS ---
  Future<void> pickFile(BuildContext context) async {
    if (!state.canAddMoreFiles) {
      Utils.showSnackBar(
        context,
        "Max ${state.maxFiles} files allowed.",
        AppColors.error,
      );
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'doc', 'pptx', 'ppt', 'txt'],
    );
    if (result.isNotEmpty) {
      final current = List<PlatformFile>.from(state.selectedFiles);
      for (final file in result) {
        if (current.length >= state.maxFiles) break;
        final size = await file.length();
        if (size > state.maxFileSizeInBytes) {
          if (context.mounted) {
            Utils.showSnackBar(
              context,
              "${file.name} exceeds 10 MB limit.",
              AppColors.error,
            );
          }
          continue;
        }
        if (!current.any((f) => f.name == file.name)) {
          current.add(file);
        }
      }
      state = state.copyWith(selectedFiles: current);
    }
  }

  void removeFile(PlatformFile file) {
    final updated = List<PlatformFile>.from(state.selectedFiles)
      ..removeWhere((f) => f.name == file.name && f.path == file.path);
    state = state.copyWith(selectedFiles: updated);
  }

  void addCustomQuestion() {
    final defaultType = state.activeSubjectiveIngredientNames.first;
    final list = [...state.customQuestions, CustomQuestionState(type: defaultType, onChanged: _bump)];
    state = state.copyWith(customQuestions: list);
  }

  void removeCustomQuestion(int index) {
    final list = List<CustomQuestionState>.from(state.customQuestions);
    list[index].dispose();
    list.removeAt(index);
    state = state.copyWith(customQuestions: list);
  }

  void toggleCustomQuestionAI(int index, bool val) {
    state.customQuestions[index].useAI = val;
    _bump();
  }

  void updateCustomQuestionType(int index, String type) {
    state.customQuestions[index].type = type;
    _bump();
  }

  void updateCustomQuestionClo(int index, String? clo) {
    state.customQuestions[index].targetClo = clo;
    _bump();
  }

  void addSubPartToCustomQuestion(int qIndex) {
    state.customQuestions[qIndex].subParts.add(SubPartState(onChanged: _bump));
    _bump();
  }

  void removeSubPartFromCustomQuestion(int qIndex, int spIndex) {
    final sp = state.customQuestions[qIndex].subParts.removeAt(spIndex);
    sp.dispose();
    _bump();
  }

  void addScenarioQuestion() {
    final list = [...state.scenarioQuestions, ScenarioQuestionState(onChanged: _bump)];
    state = state.copyWith(scenarioQuestions: list);
  }

  void removeScenarioQuestion(int index) {
    final list = List<ScenarioQuestionState>.from(state.scenarioQuestions);
    list[index].dispose();
    list.removeAt(index);
    state = state.copyWith(scenarioQuestions: list);
  }

  void updateScenarioType(int index, String type) {
    state.scenarioQuestions[index].type = type;
    _bump();
  }

  void toggleScenarioAI(int index, bool val) {
    state.scenarioQuestions[index].useAI = val;
    _bump();
  }

  void updateScenarioMergeCategory(int index, String category) {
    state.scenarioQuestions[index].mergeCategory = category;
    _bump();
  }

  void updateScenarioClo(int index, String? clo) {
    state.scenarioQuestions[index].targetClo = clo;
    _bump();
  }

  void addDiagramQuestion() {
    state = state.copyWith(
      diagramTextControllers: [...state.diagramTextControllers, _ctrl('')],
      diagramMarksControllers: [...state.diagramMarksControllers, _ctrl('')],
      diagramImages: [...state.diagramImages, null],
      diagramTargetCLOs: [...state.diagramTargetCLOs, null],
    );
  }

  void removeDiagramQuestion(int index) {
    final texts = List<TextEditingController>.from(state.diagramTextControllers);
    final marks = List<TextEditingController>.from(state.diagramMarksControllers);
    final imgs = List<File?>.from(state.diagramImages);
    final clos = List<String?>.from(state.diagramTargetCLOs);
    texts.removeAt(index).dispose();
    marks.removeAt(index).dispose();
    imgs.removeAt(index);
    clos.removeAt(index);
    state = state.copyWith(
      diagramTextControllers: texts,
      diagramMarksControllers: marks,
      diagramImages: imgs,
      diagramTargetCLOs: clos,
    );
  }

  void updateDiagramClo(int index, String? clo) {
    final clos = List<String?>.from(state.diagramTargetCLOs);
    clos[index] = clo;
    state = state.copyWith(diagramTargetCLOs: clos);
  }

  Future<void> pickDiagramImage(int index, ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      final imgs = List<File?>.from(state.diagramImages);
      imgs[index] = File(picked.path);
      state = state.copyWith(diagramImages: imgs);
    }
  }

  bool validateCourseConfig() {
    if (state.selectedCourseCode == null) return false;

    bool validateRandom(TextEditingController qty, TextEditingController marks) {
      final q = double.tryParse(qty.text.trim()) ?? 0;
      final m = double.tryParse(marks.text.trim()) ?? 0;
      return q > 0 && m > 0;
    }

    if (state.randomMCQs && !validateRandom(state.globalMcqQtyCtrl, state.globalMcqMarksCtrl)) return false;
    if (state.randomFillBlanks && !validateRandom(state.globalFibQtyCtrl, state.globalFibMarksCtrl)) return false;
    if (state.randomShortQs && !validateRandom(state.globalShortQtyCtrl, state.globalShortMarksCtrl)) return false;
    if (state.randomLongQs && !validateRandom(state.globalLongQtyCtrl, state.globalLongMarksCtrl)) return false;

    return true;
  }

  bool validateCustomQuestions() {
    if (!state.wantsCustomQuestions) return true;
    for (final q in state.customQuestions) {
      if (q.targetClo == null || q.textCtrl.text.trim().isEmpty) return false;
      if (q.subParts.isEmpty && (double.tryParse(q.marksCtrl.text) ?? 0) <= 0) return false;
      for (final sp in q.subParts) {
        if (!q.useAI && sp.hintCtrl.text.trim().isEmpty) return false;
        if ((double.tryParse(sp.marksCtrl.text) ?? 0) <= 0) return false;
      }
    }
    return true;
  }

  bool validateScenarios() {
    if (!state.wantsScenariosOrCode) return true;
    for (final s in state.scenarioQuestions) {
      if (s.targetClo == null || s.textCtrl.text.trim().isEmpty) return false;
      if ((double.tryParse(s.marksCtrl.text) ?? 0) <= 0) return false;
    }
    return true;
  }

  bool validateDiagrams() {
    if (!state.wantsDiagrams) return true;
    for (int i = 0; i < state.diagramTextControllers.length; i++) {
      if (state.diagramImages[i] == null ||
          state.diagramTargetCLOs[i] == null ||
          state.diagramTextControllers[i].text.trim().isEmpty ||
          (double.tryParse(state.diagramMarksControllers[i].text) ?? 0) <= 0) {
        return false;
      }
    }
    return true;
  }

  String? validateFinalMatrix() {
    if (state.importedCLOs.where((c) => c['isSelected'] == true).isEmpty) {
      return "Please select at least one CLO.";
    }
    if (state.currentConfiguredMarks != state.currentTargetMarks) {
      return "Total marks (${state.currentConfiguredMarks}) must equal Target Marks (${state.currentTargetMarks}).";
    }
    return null;
  }

  String _cleanJson(String raw) => raw.replaceAll('```json', '').replaceAll('```', '').trim();

  // DYNAMIC BLUEPRINT WITHOUT ASKING FOR MARKS
  String _buildExactBlueprint() {
    final buffer = StringBuffer("\n--- STRICT EXAM BLUEPRINT (FOLLOW THESE QUANTITIES EXACTLY) ---\n");

    void addGlobal(String name, TextEditingController qty) {
      final q = qty.text.trim();
      if (q.isNotEmpty && q != '0') {
        buffer.writeln("- $name: Exactly $q questions (Assign relevant CLOs natively).");
      }
    }

    void addClo(String name, String qtyKey) {
      buffer.write("- $name: ");
      bool added = false;
      for (int i = 0; i < state.importedCLOs.length; i++) {
        if (state.importedCLOs[i]['isSelected'] == true) {
          final q = (state.importedCLOs[i][qtyKey] as TextEditingController).text.trim();
          if (q.isNotEmpty && q != '0') {
            buffer.write("CLO ${i + 1} -> $q questions. ");
            added = true;
          }
        }
      }
      if (added) buffer.writeln();
    }

    if (state.wantsMCQs) state.randomMCQs ? addGlobal("MCQs", state.globalMcqQtyCtrl) : addClo("MCQs", 'mcq_qty');
    if (state.wantsFillBlanks) state.randomFillBlanks ? addGlobal("Fill in the Blanks", state.globalFibQtyCtrl) : addClo("Fill in the Blanks", 'fib_qty');
    if (state.wantsShortQs) state.randomShortQs ? addGlobal("Short Questions", state.globalShortQtyCtrl) : addClo("Short Questions", 'short_qty');
    if (state.wantsLongQs) state.randomLongQs ? addGlobal("Long Questions", state.globalLongQtyCtrl) : addClo("Long Questions", 'long_qty');

    return buffer.toString();
  }

  String _buildDynamicPrompt() {
    List<String> requiredKeys = ['"title"', '"custom_scenarios"', '"diagram_questions"'];

    if (state.wantsMCQs) requiredKeys.add('"mcqs" (list of {question, options, correctAnswer, target_clo})');
    if (state.wantsFillBlanks) requiredKeys.add('"fillInTheBlanks" (list of {question, answer, target_clo})');
    if (state.wantsShortQs) requiredKeys.add('"shortQuestions" (list of {question, idealAnswer, target_clo})');
    if (state.wantsLongQs) requiredKeys.add('"longQuestions" (list of {question, gradingRubric, target_clo})');

    String prompt = """
      Generate a university exam in strict RAW JSON format (no markdown blocks) for ${state.selectedCourseCode}: ${state.selectedCourseTitle} (${state.selectedExamType}).
      Required JSON keys: ${requiredKeys.join(', ')}.
      
      DO NOT INCLUDE A "marks" FIELD ANYWHERE. WE HANDLE MARKS INTERNALLY.
      
      ${_buildExactBlueprint()}
      """;

    List<String> exclusions = [];
    if (!state.wantsMCQs) exclusions.add('"mcqs"');
    if (!state.wantsFillBlanks) exclusions.add('"fillInTheBlanks"');
    if (!state.wantsShortQs) exclusions.add('"shortQuestions"');
    if (!state.wantsLongQs) exclusions.add('"longQuestions"');
    if (exclusions.isNotEmpty) {
      prompt += "\nCRITICAL: DO NOT include the following keys under any circumstances: ${exclusions.join(', ')}.";
    }
    return prompt;
  }

  // --- DETERMINISTIC MARKS INJECTION HELPERS ---
  double _getMarkFromClo(String targetClo, String marksKey) {
    if (targetClo.isEmpty) return 0.0;
    final match = RegExp(r'\d+').firstMatch(targetClo);
    if (match != null) {
      int index = int.parse(match.group(0)!) - 1;
      if (index >= 0 && index < state.importedCLOs.length) {
        final ctrl = state.importedCLOs[index][marksKey] as TextEditingController?;
        return double.tryParse(ctrl?.text.trim() ?? '0') ?? 0.0;
      }
    }
    return 0.0;
  }

  double _getMarkForQuestion(String type, String targetClo) {
    if (type == 'mcqs') {
      return state.randomMCQs ? (double.tryParse(state.globalMcqMarksCtrl.text) ?? 0.0) : _getMarkFromClo(targetClo, 'mcq_marks');
    } else if (type == 'fillInTheBlanks') {
      return state.randomFillBlanks ? (double.tryParse(state.globalFibMarksCtrl.text) ?? 0.0) : _getMarkFromClo(targetClo, 'fib_marks');
    } else if (type == 'shortQuestions') {
      return state.randomShortQs ? (double.tryParse(state.globalShortMarksCtrl.text) ?? 0.0) : _getMarkFromClo(targetClo, 'short_marks');
    } else if (type == 'longQuestions') {
      return state.randomLongQs ? (double.tryParse(state.globalLongMarksCtrl.text) ?? 0.0) : _getMarkFromClo(targetClo, 'long_marks');
    }
    return 0.0;
  }

  // Intercepts the raw JSON and forcefully injects correct float marks natively
  void _injectDeterministicMarks(JsonMap data) {
    final types = ['mcqs', 'fillInTheBlanks', 'shortQuestions', 'longQuestions'];
    for (String type in types) {
      if (data[type] != null && data[type] is List) {
        for (var q in data[type]) {
          String clo = q['target_clo']?.toString() ?? '';
          q['marks'] = _getMarkForQuestion(type, clo); // Injected!
        }
      }
    }
  }

  Future<bool> triggerGeneration(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    final apiKey = ref.read(authProvider).customApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      if (context.mounted) Utils.showSnackBar(context, "API Key missing in Settings.", AppColors.error);
      state = state.copyWith(isLoading: false);
      return false; // Return false on error
    }

    try {
      final model = GenerativeModel(model: 'gemini-3.6-flash', apiKey: apiKey);
      final promptStr = _buildDynamicPrompt();

      List<Part> parts = [TextPart(promptStr)];
      for (var file in state.selectedFiles) {
        final bytes = await File(file.path!).readAsBytes();
        final mimeType = file.name.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'text/plain';
        parts.add(DataPart(mimeType, bytes));
      }

      final res = await model.generateContent([Content.multi(parts)]);
      final JsonMap data = jsonDecode(_cleanJson(res.text ?? "{}"));

      _injectDeterministicMarks(data);

      data['custom_scenarios'] = [
        ...state.customQuestions.map((q) => {
          'type': q.type,
          'question': q.textCtrl.text,
          'marks': double.tryParse(q.marksCtrl.text) ?? 0.0,
          'target_clo': q.targetClo,
          'sub_parts': q.subParts.asMap().entries.map((e) => {
            'label': String.fromCharCode(97 + e.key),
            'question': e.value.hintCtrl.text,
            'marks': double.tryParse(e.value.marksCtrl.text) ?? 0.0,
          }).toList(),
        }),
        ...state.scenarioQuestions.map((s) => {
          'type': s.type,
          'question': s.textCtrl.text,
          'marks': double.tryParse(s.marksCtrl.text) ?? 0.0,
          'target_clo': s.targetClo,
        }),
      ];

      data['diagram_questions'] = List.generate(state.diagramTextControllers.length, (i) => {
        'question': state.diagramTextControllers[i].text,
        'marks': double.tryParse(state.diagramMarksControllers[i].text) ?? 0.0,
        'target_clo': state.diagramTargetCLOs[i],
        'image_url': state.diagramImages[i]?.path ?? '',
      });

      data['meta_course_title'] = state.selectedCourseTitle;
      data['meta_course_code'] = state.selectedCourseCode;
      data['meta_credit_hours'] = state.courseCreditHours;
      data['meta_department'] = state.selectedDepartmentName;
      data['meta_exam_type'] = state.selectedExamType;
      data['meta_total_marks'] = state.currentTargetMarks;

      state = state.copyWith(generatedAssessment: data, isLoading: false);

      // Save it perfectly to history!
      await ref.read(historyProvider.notifier).saveAssessment(data);
      return true;

    } catch (e) {
      if (e.toString().contains('503')) {
        Utils.showSnackBar(context, "Generation failed: AI servers are currently busy.", AppColors.error);
      } else if (context.mounted) {
        Utils.showSnackBar(context, "Generation failed: $e", AppColors.error);
      }
      state = state.copyWith(isLoading: false);
      return false; // Return false on error
    }
  }

  bool isRegenerating(String type, int index) => state.regeneratingItemKey == "${type}_$index";

  Future<void> regenerateSingleItem(BuildContext context, String type, int index) async {
    if (state.generatedAssessment == null) return;
    state = state.copyWith(regeneratingItemKey: "${type}_$index");
    final apiKey = ref.read(authProvider).customApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(regeneratingItemKey: "CLEAR");
      return;
    }

    try {
      final list = List<dynamic>.from(state.generatedAssessment![type] ?? []);
      final model = GenerativeModel(model: 'gemini-3.6-flash', apiKey: apiKey);
      final prompt = "Replace this $type exam question with a new one using the exact same JSON keys (DO NOT generate a 'marks' field, raw JSON only): ${jsonEncode(list[index])}";
      final res = await model.generateContent([Content.text(prompt)]);

      final JsonMap newQ = jsonDecode(_cleanJson(res.text ?? "{}"));
      String clo = newQ['target_clo']?.toString() ?? '';
      newQ['marks'] = _getMarkForQuestion(type, clo); // Natively mapped!

      list[index] = newQ;
      final updated = JsonMap.from(state.generatedAssessment!);
      updated[type] = list;
      state = state.copyWith(generatedAssessment: updated, regeneratingItemKey: "CLEAR");
    } catch (e) {
      if (e.toString().contains('503')) {
        Utils.showSnackBar(context, "Regeneration failed: AI servers are busy.", AppColors.error);
      } else if (context.mounted) {
        Utils.showSnackBar(context, "Regeneration failed.", AppColors.error);
      }
      state = state.copyWith(regeneratingItemKey: "CLEAR");
    }
  }
}

final assessmentProvider = NotifierProvider<AssessmentNotifier, AssessmentState>(() {
  return AssessmentNotifier();
});