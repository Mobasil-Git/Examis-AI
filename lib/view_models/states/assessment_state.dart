import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

typedef JsonMap = Map<String, dynamic>;

class SubPartState {
  final TextEditingController hintCtrl;
  final TextEditingController marksCtrl;

  SubPartState({String hint = '', String marks = '', VoidCallback? onChanged})
      : hintCtrl = TextEditingController(text: hint),
        marksCtrl = TextEditingController(text: marks) {
    if (onChanged != null) {
      marksCtrl.addListener(onChanged);
    }
  }

  void dispose() {
    hintCtrl.dispose();
    marksCtrl.dispose();
  }
}

class CustomQuestionState {
  String type;
  bool useAI;
  String? targetClo;
  final TextEditingController textCtrl;
  final TextEditingController marksCtrl;
  final List<SubPartState> subParts;

  CustomQuestionState({
    this.type = 'Short Question',
    this.useAI = true,
    this.targetClo,
    String text = '',
    String marks = '',
    List<SubPartState>? subParts,
    VoidCallback? onChanged,
  })  : textCtrl = TextEditingController(text: text),
        marksCtrl = TextEditingController(text: marks),
        subParts = subParts ?? [] {
    if (onChanged != null) {
      marksCtrl.addListener(onChanged);
    }
  }

  void dispose() {
    textCtrl.dispose();
    marksCtrl.dispose();
    for (final sp in subParts) {
      sp.dispose();
    }
  }
}

class ScenarioQuestionState {
  String type;
  bool useAI;
  String mergeCategory;
  String? targetClo;
  final TextEditingController langCtrl;
  final TextEditingController textCtrl;
  final TextEditingController marksCtrl;

  ScenarioQuestionState({
    this.type = 'Scenario',
    this.useAI = true,
    this.mergeCategory = 'Stand-alone',
    this.targetClo,
    String lang = 'Python',
    String text = '',
    String marks = '',
    VoidCallback? onChanged,
  })  : langCtrl = TextEditingController(text: lang),
        textCtrl = TextEditingController(text: text),
        marksCtrl = TextEditingController(text: marks) {
    if (onChanged != null) {
      marksCtrl.addListener(onChanged);
    }
  }

  void dispose() {
    langCtrl.dispose();
    textCtrl.dispose();
    marksCtrl.dispose();
  }
}

class AssessmentState {
  // Ingredient Toggles
  final bool wantsMCQs;
  final bool wantsFillBlanks;
  final bool wantsShortQs;
  final bool wantsLongQs;
  final bool wantsCustomQuestions;
  final bool wantsScenariosOrCode;
  final bool wantsDiagrams;

  // Randomize Toggles
  final bool randomMCQs;
  final bool randomFillBlanks;
  final bool randomShortQs;
  final bool randomLongQs;

  // Course & Exam Config
  final String? selectedCourseCode;
  final String? selectedCourseTitle;
  final String courseCreditHours;
  final String? selectedDepartmentName;
  final List<JsonMap> importedCLOs;
  final String selectedExamType;
  final double currentTargetMarks;
  final int vivaWeightage;

  // Global Random Controllers
  final TextEditingController globalMcqQtyCtrl;
  final TextEditingController globalMcqMarksCtrl;
  final TextEditingController globalFibQtyCtrl;
  final TextEditingController globalFibMarksCtrl;
  final TextEditingController globalShortQtyCtrl;
  final TextEditingController globalShortMarksCtrl;
  final TextEditingController globalLongQtyCtrl;
  final TextEditingController globalLongMarksCtrl;

  // Advanced Step Lists
  final List<PlatformFile> selectedFiles;
  final List<CustomQuestionState> customQuestions;
  final List<ScenarioQuestionState> scenarioQuestions;
  final List<TextEditingController> diagramTextControllers;
  final List<TextEditingController> diagramMarksControllers;
  final List<File?> diagramImages;
  final List<String?> diagramTargetCLOs;

  // Generation Status
  final bool isLoading;
  final JsonMap? generatedAssessment;
  final String? regeneratingItemKey;
  final int revision;

  const AssessmentState({
    this.wantsMCQs = false,
    this.wantsFillBlanks = false,
    this.wantsShortQs = false,
    this.wantsLongQs = false,
    this.wantsCustomQuestions = false,
    this.wantsScenariosOrCode = false,
    this.wantsDiagrams = false,
    this.randomMCQs = false,
    this.randomFillBlanks = false,
    this.randomShortQs = false,
    this.randomLongQs = false,
    this.selectedCourseCode,
    this.selectedCourseTitle,
    this.courseCreditHours = "3(3-0)",
    this.selectedDepartmentName,
    this.importedCLOs = const [],
    this.selectedExamType = "Mid-Term",
    this.currentTargetMarks = 18.0,
    this.vivaWeightage = 10,
    required this.globalMcqQtyCtrl,
    required this.globalMcqMarksCtrl,
    required this.globalFibQtyCtrl,
    required this.globalFibMarksCtrl,
    required this.globalShortQtyCtrl,
    required this.globalShortMarksCtrl,
    required this.globalLongQtyCtrl,
    required this.globalLongMarksCtrl,
    this.selectedFiles = const [],
    this.customQuestions = const [],
    this.scenarioQuestions = const [],
    this.diagramTextControllers = const [],
    this.diagramMarksControllers = const [],
    this.diagramImages = const [],
    this.diagramTargetCLOs = const [],
    this.isLoading = false,
    this.generatedAssessment,
    this.regeneratingItemKey,
    this.revision = 0,
  });

  int get maxFiles => 3;
  int get maxFileSizeInBytes => 10 * 1024 * 1024;
  bool get canAddMoreFiles => selectedFiles.length < maxFiles;

  bool get hasSelectedIngredients =>
      wantsMCQs ||
          wantsFillBlanks ||
          wantsShortQs ||
          wantsLongQs ||
          wantsCustomQuestions ||
          wantsScenariosOrCode ||
          wantsDiagrams;

  // Parses Y from X(Y-Z) or (Y-Z)
  int get theoryCredits {
    final match = RegExp(r'\(\s*(\d+)\s*-\s*(\d+)\s*\)').firstMatch(courseCreditHours);
    if (match != null) return int.parse(match.group(1)!);
    return int.tryParse(courseCreditHours.trim()) ?? 3;
  }

  // Parses Z from X(Y-Z) or (Y-Z)
  int get practicalCredits {
    final match = RegExp(r'\(\s*(\d+)\s*-\s*(\d+)\s*\)').firstMatch(courseCreditHours);
    return match != null ? int.parse(match.group(2)!) : 0;
  }

  bool get hasPractical => practicalCredits > 0;

  int get labTaskWeightage =>
      (currentTargetMarks.toInt() - vivaWeightage).clamp(0, 100);

  List<String> get activeSubjectiveIngredientNames {
    final names = <String>[];
    if (wantsShortQs) names.add('Short Question');
    if (wantsLongQs) names.add('Long Question');
    if (names.isEmpty) names.addAll(['Short Question', 'Long Question']);
    return names;
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0.0;

  double get currentConfiguredMarks {
    if (selectedExamType == 'Practical') return currentTargetMarks;
    double total = 0.0;

    if (wantsMCQs) {
      if (randomMCQs) {
        total += _parse(globalMcqQtyCtrl) * _parse(globalMcqMarksCtrl);
      } else {
        for (final c in importedCLOs.where((c) => c['isSelected'] == true)) {
          total += _parse(c['mcq_qty']) * _parse(c['mcq_marks']);
        }
      }
    }
    if (wantsFillBlanks) {
      if (randomFillBlanks) {
        total += _parse(globalFibQtyCtrl) * _parse(globalFibMarksCtrl);
      } else {
        for (final c in importedCLOs.where((c) => c['isSelected'] == true)) {
          total += _parse(c['fib_qty']) * _parse(c['fib_marks']);
        }
      }
    }
    if (wantsShortQs) {
      if (randomShortQs) {
        total += _parse(globalShortQtyCtrl) * _parse(globalShortMarksCtrl);
      } else {
        for (final c in importedCLOs.where((c) => c['isSelected'] == true)) {
          total += _parse(c['short_qty']) * _parse(c['short_marks']);
        }
      }
    }
    if (wantsLongQs) {
      if (randomLongQs) {
        total += _parse(globalLongQtyCtrl) * _parse(globalLongMarksCtrl);
      } else {
        for (final c in importedCLOs.where((c) => c['isSelected'] == true)) {
          total += _parse(c['long_qty']) * _parse(c['long_marks']);
        }
      }
    }
    if (wantsCustomQuestions) {
      for (final q in customQuestions) {
        if (q.subParts.isNotEmpty) {
          for (final sp in q.subParts) {
            total += _parse(sp.marksCtrl);
          }
        } else {
          total += _parse(q.marksCtrl);
        }
      }
    }
    if (wantsScenariosOrCode) {
      for (final s in scenarioQuestions) {
        total += _parse(s.marksCtrl);
      }
    }
    if (wantsDiagrams) {
      for (final mCtrl in diagramMarksControllers) {
        total += _parse(mCtrl);
      }
    }
    return total;
  }

  AssessmentState copyWith({
    bool? wantsMCQs,
    bool? wantsFillBlanks,
    bool? wantsShortQs,
    bool? wantsLongQs,
    bool? wantsCustomQuestions,
    bool? wantsScenariosOrCode,
    bool? wantsDiagrams,
    bool? randomMCQs,
    bool? randomFillBlanks,
    bool? randomShortQs,
    bool? randomLongQs,
    String? selectedCourseCode,
    String? selectedCourseTitle,
    String? courseCreditHours,
    String? selectedDepartmentName,
    List<JsonMap>? importedCLOs,
    String? selectedExamType,
    double? currentTargetMarks,
    int? vivaWeightage,
    List<PlatformFile>? selectedFiles,
    List<CustomQuestionState>? customQuestions,
    List<ScenarioQuestionState>? scenarioQuestions,
    List<TextEditingController>? diagramTextControllers,
    List<TextEditingController>? diagramMarksControllers,
    List<File?>? diagramImages,
    List<String?>? diagramTargetCLOs,
    bool? isLoading,
    JsonMap? generatedAssessment,
    String? regeneratingItemKey,
    int? revision,
  }) {
    return AssessmentState(
      wantsMCQs: wantsMCQs ?? this.wantsMCQs,
      wantsFillBlanks: wantsFillBlanks ?? this.wantsFillBlanks,
      wantsShortQs: wantsShortQs ?? this.wantsShortQs,
      wantsLongQs: wantsLongQs ?? this.wantsLongQs,
      wantsCustomQuestions: wantsCustomQuestions ?? this.wantsCustomQuestions,
      wantsScenariosOrCode: wantsScenariosOrCode ?? this.wantsScenariosOrCode,
      wantsDiagrams: wantsDiagrams ?? this.wantsDiagrams,
      randomMCQs: randomMCQs ?? this.randomMCQs,
      randomFillBlanks: randomFillBlanks ?? this.randomFillBlanks,
      randomShortQs: randomShortQs ?? this.randomShortQs,
      randomLongQs: randomLongQs ?? this.randomLongQs,
      selectedCourseCode: selectedCourseCode ?? this.selectedCourseCode,
      selectedCourseTitle: selectedCourseTitle ?? this.selectedCourseTitle,
      courseCreditHours: courseCreditHours ?? this.courseCreditHours,
      selectedDepartmentName: selectedDepartmentName ?? this.selectedDepartmentName,
      importedCLOs: importedCLOs ?? this.importedCLOs,
      selectedExamType: selectedExamType ?? this.selectedExamType,
      currentTargetMarks: currentTargetMarks ?? this.currentTargetMarks,
      vivaWeightage: vivaWeightage ?? this.vivaWeightage,
      globalMcqQtyCtrl: globalMcqQtyCtrl,
      globalMcqMarksCtrl: globalMcqMarksCtrl,
      globalFibQtyCtrl: globalFibQtyCtrl,
      globalFibMarksCtrl: globalFibMarksCtrl,
      globalShortQtyCtrl: globalShortQtyCtrl,
      globalShortMarksCtrl: globalShortMarksCtrl,
      globalLongQtyCtrl: globalLongQtyCtrl,
      globalLongMarksCtrl: globalLongMarksCtrl,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      customQuestions: customQuestions ?? this.customQuestions,
      scenarioQuestions: scenarioQuestions ?? this.scenarioQuestions,
      diagramTextControllers: diagramTextControllers ?? this.diagramTextControllers,
      diagramMarksControllers: diagramMarksControllers ?? this.diagramMarksControllers,
      diagramImages: diagramImages ?? this.diagramImages,
      diagramTargetCLOs: diagramTargetCLOs ?? this.diagramTargetCLOs,
      isLoading: isLoading ?? this.isLoading,
      generatedAssessment: generatedAssessment ?? this.generatedAssessment,
      regeneratingItemKey: regeneratingItemKey == "CLEAR"
          ? null
          : (regeneratingItemKey ?? this.regeneratingItemKey),
      revision: revision ?? this.revision,
    );
  }
}