import 'package:examisai/view_models/history_view_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_view_model.dart';
import '../repository/assessment_repository.dart';
import '../repository/document_repository.dart';
import '../repository/gemini_repository.dart';
import '../utils/utils.dart';
import 'package:provider/provider.dart';

class AdvancedSubPartState {
  final TextEditingController hintCtrl = TextEditingController();
  final TextEditingController marksCtrl = TextEditingController();

  void dispose() {
    hintCtrl.dispose();
    marksCtrl.dispose();
  }
}

class AdvancedQuestionState {
  final TextEditingController textCtrl = TextEditingController();
  final TextEditingController marksCtrl = TextEditingController();
  final TextEditingController langCtrl = TextEditingController();
  String type = 'Custom Question';
  String mergeCategory = 'Stand-alone';
  String? targetClo;
  bool useAI = true;
  List<AdvancedSubPartState> subParts = [];

  void dispose() {
    textCtrl.dispose();
    marksCtrl.dispose();
    langCtrl.dispose();
    for (var sp in subParts) {
      sp.dispose();
    }
  }

  double get totalMarks {
    if (subParts.isEmpty) {
      return double.tryParse(marksCtrl.text) ?? 0.0;
    } else {
      return subParts.fold(
        0.0,
            (sum, part) => sum + (double.tryParse(part.marksCtrl.text) ?? 0.0),
      );
    }
  }
}

class AssessmentViewModel extends ChangeNotifier {
  final AssessmentRepository _assessmentRepo = AssessmentRepository();
  final DocumentRepository _documentRepo = DocumentRepository();
  final GeminiRepository _geminiRepo = GeminiRepository();

  bool isDemoMode = false;
  String? selectedCourseCode;
  String? selectedCourseTitle;
  String courseCreditHours = "3(3-0)";
  List<Map<String, dynamic>> importedCLOs = [];
  String? selectedDepartmentName;

  // INGREDIENTS
  bool wantsMCQs = false;
  bool randomMCQs = false;
  bool wantsFillBlanks = false;
  bool randomFillBlanks = false;
  bool wantsShortQs = false;
  bool randomShortQs = false;
  bool wantsLongQs = false;
  bool randomLongQs = false;
  bool wantsScenariosOrCode = false;
  bool wantsCustomQuestions = false;
  bool wantsDiagrams = false;

  bool get hasSelectedIngredients =>
      wantsMCQs ||
      wantsFillBlanks ||
      wantsShortQs ||
      wantsLongQs ||
      wantsScenariosOrCode ||
      wantsCustomQuestions ||
      wantsDiagrams;

  List<String> get activeSubjectiveIngredientNames {
    List<String> names = [];
    if (wantsShortQs) names.add('Short Question');
    if (wantsLongQs) names.add('Long Question');
    if (names.isEmpty) names.add('Custom Question');
    return names;
  }

  List<Map<String, dynamic>> _departments = [];

  List<Map<String, dynamic>> get departments => _departments;

  Map<String, dynamic>? _generalDepartment;

  Map<String, dynamic>? get generalDepartment => _generalDepartment;

  List<Map<String, dynamic>> _availableBatches = [];
  Map<String, dynamic>? _selectedBatch;

  List<Map<String, dynamic>> get availableBatches => _availableBatches;

  Map<String, dynamic>? get selectedBatch => _selectedBatch;

  List<Map<String, dynamic>> _filteredMasterCourses = [];

  List<Map<String, dynamic>> get filteredMasterCourses =>
      _filteredMasterCourses;

  String selectedPaperCategory = 'Theory Based';

  final TextEditingController globalMcqQtyCtrl = TextEditingController();
  final TextEditingController globalMcqMarksCtrl = TextEditingController();
  final TextEditingController globalFibQtyCtrl = TextEditingController();
  final TextEditingController globalFibMarksCtrl = TextEditingController();
  final TextEditingController globalShortQtyCtrl = TextEditingController();
  final TextEditingController globalShortMarksCtrl = TextEditingController();
  final TextEditingController globalLongQtyCtrl = TextEditingController();
  final TextEditingController globalLongMarksCtrl = TextEditingController();

  // ADVANCED BUILDER LISTS
  List<AdvancedQuestionState> scenarioQuestions = [];
  List<AdvancedQuestionState> customQuestions = [];

  List<TextEditingController> diagramTextControllers = [];
  List<TextEditingController> diagramMarksControllers = [];
  List<File?> diagramImages = [];
  List<String?> diagramTargetCLOs = [];

  static const int _draftExpirationMinutes = 15;

  String selectedExamType = 'Mid-Term';
  int midTermTarget = 0;
  int finalTermTarget = 0;
  int practicalTarget = 0;
  bool hasPractical = true;
  int vivaWeightage = 0;
  int labTaskWeightage = 0;

  final List<PlatformFile> _selectedFiles = [];
  final int maxFiles = 3;
  final int maxFileSizeInBytes = 10 * 1024 * 1024;

  List<PlatformFile> get selectedFiles => _selectedFiles;

  bool get canAddMoreFiles => _selectedFiles.length < maxFiles;

  bool _isLoading = false;
  Map<String, dynamic>? _generatedAssessment;

  bool get isLoading => _isLoading;

  Map<String, dynamic>? get generatedAssessment => _generatedAssessment;

  String _lastDocumentText = "";
  final Set<String> _regeneratingItems = {};

  bool isRegenerating(String type, int index) =>
      _regeneratingItems.contains("${type}_$index");

  AssessmentViewModel() {
    _loadDraft();
    _attachSaveListeners();
    if (scenarioQuestions.isEmpty) _addScenarioQuestionSilent();
    if (customQuestions.isEmpty) _addCustomQuestionSilent();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _onFormChanged() {
    _saveDraft();
    notifyListeners();
  }

  void toggleIngredient(String type, bool? value) {
    if (value == null) return;
    switch (type) {
      case 'mcq':
        wantsMCQs = value;
        if (!value) randomMCQs = false;
        break;
      case 'fib':
        wantsFillBlanks = value;
        if (!value) randomFillBlanks = false;
        break;
      case 'short':
        wantsShortQs = value;
        if (!value) randomShortQs = false;
        break;
      case 'long':
        wantsLongQs = value;
        if (!value) randomLongQs = false;
        break;
      case 'scenario':
        wantsScenariosOrCode = value;
        break;
      case 'custom':
        wantsCustomQuestions = value;
        break;
      case 'diagram':
        wantsDiagrams = value;
        break;
    }
    _onFormChanged();
  }

  void toggleRandomIngredient(String type, bool? value) {
    if (value == null) return;
    switch (type) {
      case 'mcq':
        randomMCQs = value;
        break;
      case 'fib':
        randomFillBlanks = value;
        break;
      case 'short':
        randomShortQs = value;
        break;
      case 'long':
        randomLongQs = value;
        break;
    }
    _onFormChanged();
  }

  Future<void> fetchDepartments() async {
    try {
      _departments = await _assessmentRepo.fetchDepartments();
      try {
        _generalDepartment = _departments.firstWhere(
          (dept) => dept['name'].toString().contains('General'),
        );
      } catch (e) {}
      notifyListeners();
    } catch (e) {}
  }

  Future<void> fetchBatches() async {
    try {
      _availableBatches = await _assessmentRepo.fetchBatches();
      if (_availableBatches.isNotEmpty)
        _selectedBatch ??= _availableBatches.first;
      notifyListeners();
    } catch (e) {}
  }

  Future<bool> createNewBatch(int startYear, int endYear) async {
    try {
      final bool alreadyExists = _availableBatches.any(
        (batch) =>
            batch['start_year'] == startYear && batch['end_year'] == endYear,
      );
      if (alreadyExists) return false;
      final String batchName = "Session $startYear-$endYear";
      final newBatch = await _assessmentRepo.createNewBatch(
        startYear,
        endYear,
        batchName,
      );
      _availableBatches.add(newBatch);
      _availableBatches.sort(
        (a, b) => (b['start_year'] as int).compareTo(a['start_year'] as int),
      );
      _selectedBatch = newBatch;
      notifyListeners();
      fetchCoursesForSelectedBatch();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchCoursesForSelectedBatch() async {
    if (_selectedBatch == null) return;
    try {
      _filteredMasterCourses = await _assessmentRepo.fetchCoursesByBatch(
        _selectedBatch!['id'],
      );
      notifyListeners();
    } catch (e) {}
  }

  void updateSelectedBatch(Map<String, dynamic>? newBatch) {
    if (newBatch != null) {
      _selectedBatch = newBatch;
      notifyListeners();
      fetchCoursesForSelectedBatch();
    }
  }

  void setImportedCourse(
    String code,
    String title,
    List<Map<String, dynamic>> clos,
    String creditHours,
    String departmentName,
  ) {
    selectedCourseCode = code;
    selectedCourseTitle = title;
    selectedDepartmentName = departmentName;

    importedCLOs = clos.map((clo) {
      final modifiableClo = Map<String, dynamic>.from(clo);
      modifiableClo['isSelected'] = true;
      modifiableClo['mcq_qty'] = TextEditingController()
        ..addListener(_onFormChanged);
      modifiableClo['mcq_marks'] = TextEditingController()
        ..addListener(_onFormChanged);
      modifiableClo['fib_qty'] = TextEditingController()
        ..addListener(_onFormChanged);
      modifiableClo['fib_marks'] = TextEditingController()
        ..addListener(_onFormChanged);
      modifiableClo['short_qty'] = TextEditingController()
        ..addListener(_onFormChanged);
      modifiableClo['short_marks'] = TextEditingController()
        ..addListener(_onFormChanged);
      modifiableClo['long_qty'] = TextEditingController()
        ..addListener(_onFormChanged);
      modifiableClo['long_marks'] = TextEditingController()
        ..addListener(_onFormChanged);
      return modifiableClo;
    }).toList();

    courseCreditHours = creditHours;
    parseCreditHours(creditHours);
    notifyListeners();
  }

  void clearImportedCourse() {
    for (var clo in importedCLOs) {
      (clo['mcq_qty'] as TextEditingController?)?.dispose();
      (clo['mcq_marks'] as TextEditingController?)?.dispose();
      (clo['fib_qty'] as TextEditingController?)?.dispose();
      (clo['fib_marks'] as TextEditingController?)?.dispose();
      (clo['short_qty'] as TextEditingController?)?.dispose();
      (clo['short_marks'] as TextEditingController?)?.dispose();
      (clo['long_qty'] as TextEditingController?)?.dispose();
      (clo['long_marks'] as TextEditingController?)?.dispose();
    }
    selectedCourseCode = null;
    selectedCourseTitle = null;
    selectedDepartmentName = null;
    importedCLOs = [];
    notifyListeners();
  }

  void parseCreditHours(String chString) {
    RegExp regExp = RegExp(r'\((.*?)-(.*?)\)');
    var match = regExp.firstMatch(chString);
    if (match != null) {
      int theoryCH = int.tryParse(match.group(1) ?? '0') ?? 0;
      int practicalCH = int.tryParse(match.group(2) ?? '0') ?? 0;
      int theoryMarks = theoryCH * 20;
      midTermTarget = (theoryMarks * 0.30).round();
      finalTermTarget = (theoryMarks * 0.60).round();
      practicalTarget = practicalCH * 20;
      vivaWeightage = (practicalTarget * 0.25).round();
      labTaskWeightage = practicalTarget - vivaWeightage;
      hasPractical = practicalCH > 0;
      if (!hasPractical && selectedExamType == 'Practical')
        selectedExamType = 'Mid-Term';
      notifyListeners();
    }
  }

  void setExamType(String type) {
    selectedExamType = type;
    notifyListeners();
  }

  double get currentTargetMarks {
    if (selectedExamType == 'Mid-Term') return midTermTarget.toDouble();
    if (selectedExamType == 'Final') return finalTermTarget.toDouble();
    if (selectedExamType == 'Practical') return practicalTarget.toDouble();
    return 0.0;
  }

  double get currentConfiguredMarks {
    double total = 0.0;

    for (var clo in importedCLOs) {
      if (clo['isSelected'] == true) {
        if (wantsMCQs && !randomMCQs) total += (double.tryParse(clo['mcq_qty'].text) ?? 0.0) * (double.tryParse(clo['mcq_marks'].text) ?? 0.0);
        if (wantsFillBlanks && !randomFillBlanks) total += (double.tryParse(clo['fib_qty'].text) ?? 0.0) * (double.tryParse(clo['fib_marks'].text) ?? 0.0);
        if (wantsShortQs && !randomShortQs) total += (double.tryParse(clo['short_qty'].text) ?? 0.0) * (double.tryParse(clo['short_marks'].text) ?? 0.0);
        if (wantsLongQs && !randomLongQs) total += (double.tryParse(clo['long_qty'].text) ?? 0.0) * (double.tryParse(clo['long_marks'].text) ?? 0.0);
      }
    }

    if (wantsMCQs && randomMCQs) total += (double.tryParse(globalMcqQtyCtrl.text) ?? 0.0) * (double.tryParse(globalMcqMarksCtrl.text) ?? 0.0);
    if (wantsFillBlanks && randomFillBlanks) total += (double.tryParse(globalFibQtyCtrl.text) ?? 0.0) * (double.tryParse(globalFibMarksCtrl.text) ?? 0.0);
    if (wantsShortQs && randomShortQs) total += (double.tryParse(globalShortQtyCtrl.text) ?? 0.0) * (double.tryParse(globalShortMarksCtrl.text) ?? 0.0);
    if (wantsLongQs && randomLongQs) total += (double.tryParse(globalLongQtyCtrl.text) ?? 0.0) * (double.tryParse(globalLongMarksCtrl.text) ?? 0.0);

    if (wantsScenariosOrCode) {
      for (var q in scenarioQuestions) total += q.totalMarks;
    }
    if (wantsCustomQuestions) {
      for (var q in customQuestions) total += q.totalMarks;
    }
    if (wantsDiagrams) {
      for (var ctrl in diagramMarksControllers) total += double.tryParse(ctrl.text) ?? 0.0;
    }
    return total;
  }

  void updateVivaWeightage(String value) {
    int parsedValue = int.tryParse(value) ?? 0;
    if (parsedValue > practicalTarget) parsedValue = practicalTarget;
    if (parsedValue < 0) parsedValue = 0;
    vivaWeightage = parsedValue;
    labTaskWeightage = practicalTarget - vivaWeightage;
    notifyListeners();
  }

  void toggleCloSelection(int index, bool? value) {
    if (value != null) {
      importedCLOs[index]['isSelected'] = value;
      notifyListeners();
    }
  }

  void updatePaperCategory(String? newValue) {
    if (newValue != null) {
      selectedPaperCategory = newValue;
      _onFormChanged();
    }
  }

  // --- SCENARIO LOGIC ---
  void _addScenarioQuestionSilent() {
    final q = AdvancedQuestionState();
    q.type = 'Scenario';
    q.textCtrl.addListener(_onFormChanged);
    q.marksCtrl.addListener(_onFormChanged);
    q.langCtrl.addListener(_onFormChanged);
    scenarioQuestions.add(q);
  }

  void updateScenarioMergeCategory(int index, String newCategory) {
    scenarioQuestions[index].mergeCategory = newCategory;
    _onFormChanged();
  }

  void addScenarioQuestion() {
    _addScenarioQuestionSilent();
    _onFormChanged();
  }

  void removeScenarioQuestion(int index) {
    if (scenarioQuestions.length > 1) {
      scenarioQuestions[index].dispose();
      scenarioQuestions.removeAt(index);
      _onFormChanged();
    }
  }

  void updateScenarioType(int index, String newType) {
    scenarioQuestions[index].type = newType;
    _onFormChanged();
  }

  void updateScenarioClo(int index, String? newClo) {
    scenarioQuestions[index].targetClo = newClo;
    _onFormChanged();
  }

  // NEW: Toggle AI for Scenarios
  void toggleScenarioAI(int index, bool value) {
    scenarioQuestions[index].useAI = value;
    _onFormChanged();
  }

  // --- CUSTOM QUESTION LOGIC ---
  void _addCustomQuestionSilent() {
    final q = AdvancedQuestionState();
    q.type = activeSubjectiveIngredientNames.first;
    q.textCtrl.addListener(_onFormChanged);
    q.marksCtrl.addListener(_onFormChanged);
    customQuestions.add(q);
  }

  void addCustomQuestion() {
    _addCustomQuestionSilent();
    _onFormChanged();
  }

  void removeCustomQuestion(int index) {
    if (customQuestions.length > 1) {
      customQuestions[index].dispose();
      customQuestions.removeAt(index);
      _onFormChanged();
    }
  }

  void updateCustomQuestionType(int index, String newType) {
    customQuestions[index].type = newType;
    _onFormChanged();
  }

  void updateCustomQuestionClo(int index, String? newClo) {
    customQuestions[index].targetClo = newClo;
    _onFormChanged();
  }

  void toggleCustomQuestionAI(int index, bool value) {
    customQuestions[index].useAI = value;
    _onFormChanged();
  }

  void addSubPartToCustomQuestion(int questionIndex) {
    final sp = AdvancedSubPartState();
    sp.hintCtrl.addListener(_onFormChanged);
    sp.marksCtrl.addListener(_onFormChanged);
    customQuestions[questionIndex].subParts.add(sp);
    if (customQuestions[questionIndex].subParts.length == 1) {
      customQuestions[questionIndex].marksCtrl.clear();
    }
    _onFormChanged();
  }

  void removeSubPartFromCustomQuestion(int questionIndex, int subPartIndex) {
    customQuestions[questionIndex].subParts[subPartIndex].dispose();
    customQuestions[questionIndex].subParts.removeAt(subPartIndex);
    _onFormChanged();
  }

  // --- DIAGRAM LOGIC ---
  void addDiagramQuestion() {
    final marksCtrl = TextEditingController(text: "5")
      ..addListener(_onFormChanged);
    diagramTextControllers.add(
      TextEditingController()..addListener(_onFormChanged),
    );
    diagramMarksControllers.add(marksCtrl);
    diagramImages.add(null);
    diagramTargetCLOs.add(null);
    _onFormChanged();
  }

  void removeDiagramQuestion(int index) {
    diagramTextControllers[index].dispose();
    diagramMarksControllers[index].dispose();
    diagramTextControllers.removeAt(index);
    diagramMarksControllers.removeAt(index);
    diagramImages.removeAt(index);
    diagramTargetCLOs.removeAt(index);
    _onFormChanged();
  }

  void updateDiagramClo(int index, String? newClo) {
    diagramTargetCLOs[index] = newClo;
    _onFormChanged();
  }

  Future<void> pickDiagramImage(int index, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        diagramImages[index] = File(image.path);
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> pickFile(BuildContext context) async {
    if (!canAddMoreFiles) {
      Utils.showSnackBar(
        context,
        "You can only upload up to $maxFiles files at a time.",
        Colors.redAccent,
      );
      return;
    }
    try {
      List<PlatformFile> files =
          await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'docx', 'pptx'],
          );
      if (files.isNotEmpty) {
        for (var file in files) {
          if (_selectedFiles.any((existing) => existing.name == file.name))
            continue;
          if ((file.path != null ? File(file.path!).lengthSync() : 0) >
              maxFileSizeInBytes)
            continue;
          if (_selectedFiles.length >= maxFiles) break;
          _selectedFiles.add(file);
        }
        notifyListeners();
      }
    } catch (e) {}
  }

  void removeFile(PlatformFile fileToRemove) {
    _selectedFiles.removeWhere((file) => file.name == fileToRemove.name);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> extractCourseWithGemini(XFile imageFile) async {
    return await _geminiRepo.extractCourseSyllabusFromImage(
      File(imageFile.path),
    );
  }

  Future<void> regenerateSingleItem(
    BuildContext context,
    String type,
    int index,
  ) async {
    if (_lastDocumentText.isEmpty) {
      Utils.showSnackBar(
        context,
        "Context lost. Please generate a new assessment.",
        Colors.redAccent,
      );
      return;
    }
    final itemKey = "${type}_$index";
    _regeneratingItems.add(itemKey);
    notifyListeners();

    try {
      final oldQuestion = _generatedAssessment?[type][index];
      final String? existingClo = oldQuestion?['target_clo'];

      final newQuestion = await _geminiRepo.regenerateSingleQuestion(
        documentText: _lastDocumentText,
        questionType: type,
        paperCategory: selectedPaperCategory,
        targetClo: existingClo,
      );

      if (newQuestion != null && _generatedAssessment != null) {
        if (existingClo != null) newQuestion['target_clo'] = existingClo;
        _generatedAssessment![type][index] = newQuestion;
      } else {
        if (context.mounted)
          Utils.showSnackBar(
            context,
            "Failed to regenerate question.",
            Colors.redAccent,
          );
      }
    } catch (e) {
      if (context.mounted)
        Utils.showSnackBar(
          context,
          e.toString().replaceAll('Exception:', '').trim(),
          Colors.redAccent,
        );
    }

    _regeneratingItems.remove(itemKey);
    notifyListeners();
  }

  // --- STRICT STEP-BY-STEP VALIDATION METHODS ---

  bool validateCourseConfig() {
    if (selectedCourseCode == null) return false;

    // Upgraded to double.tryParse so decimal inputs don't fail the required fields check
    if (randomMCQs) {
      if ((double.tryParse(globalMcqQtyCtrl.text) ?? 0) <= 0 ||
          (double.tryParse(globalMcqMarksCtrl.text) ?? 0) <= 0) return false;
    }
    if (randomFillBlanks) {
      if ((double.tryParse(globalFibQtyCtrl.text) ?? 0) <= 0 ||
          (double.tryParse(globalFibMarksCtrl.text) ?? 0) <= 0) return false;
    }
    if (randomShortQs) {
      if ((double.tryParse(globalShortQtyCtrl.text) ?? 0) <= 0 ||
          (double.tryParse(globalShortMarksCtrl.text) ?? 0) <= 0) return false;
    }
    if (randomLongQs) {
      if ((double.tryParse(globalLongQtyCtrl.text) ?? 0) <= 0 ||
          (double.tryParse(globalLongMarksCtrl.text) ?? 0) <= 0) return false;
    }
    return true;
  }

  String? validateFinalMatrix() {
    final double currentMarks = currentConfiguredMarks;
    final double targetMarks = currentTargetMarks;

    if (currentMarks != targetMarks) {
      return "Total allocated marks ($currentMarks) must exactly match Target Marks ($targetMarks).";
    }

    bool hasMCQs = false;
    bool hasFIB = false;
    bool hasShort = false;
    bool hasLong = false;

    // 1. Check if standard Matrix Fields fulfill the requirement
    for (var clo in importedCLOs) {
      if (clo['isSelected'] == true) {
        if ((double.tryParse(clo['mcq_qty'].text) ?? 0) > 0 && (double.tryParse(clo['mcq_marks'].text) ?? 0) > 0) hasMCQs = true;
        if ((double.tryParse(clo['fib_qty'].text) ?? 0) > 0 && (double.tryParse(clo['fib_marks'].text) ?? 0) > 0) hasFIB = true;
        if ((double.tryParse(clo['short_qty'].text) ?? 0) > 0 && (double.tryParse(clo['short_marks'].text) ?? 0) > 0) hasShort = true;
        if ((double.tryParse(clo['long_qty'].text) ?? 0) > 0 && (double.tryParse(clo['long_marks'].text) ?? 0) > 0) hasLong = true;
      }
    }

    // 2. Check if Global Random Fields fulfill the requirement
    if (randomMCQs && (double.tryParse(globalMcqQtyCtrl.text) ?? 0) > 0) hasMCQs = true;
    if (randomFillBlanks && (double.tryParse(globalFibQtyCtrl.text) ?? 0) > 0) hasFIB = true;
    if (randomShortQs && (double.tryParse(globalShortQtyCtrl.text) ?? 0) > 0) hasShort = true;
    if (randomLongQs && (double.tryParse(globalLongQtyCtrl.text) ?? 0) > 0) hasLong = true;

    // 3. SMART RELAXATION: Automatically bypass matrix requirements if a Custom Question or Scenario is mapped to that category
    if (wantsCustomQuestions) {
      for (var q in customQuestions) {
        if (q.totalMarks > 0) {
          if (q.type == 'Short Question') hasShort = true;
          if (q.type == 'Long Question') hasLong = true;
        }
      }
    }

    if (wantsScenariosOrCode) {
      for (var q in scenarioQuestions) {
        if (q.totalMarks > 0) {
          if (q.mergeCategory == 'Short Question') hasShort = true;
          if (q.mergeCategory == 'Long Question') hasLong = true;
        }
      }
    }

    // Final Gatekeeper
    if (wantsMCQs && !hasMCQs) return "You selected Multiple Choice Questions but assigned 0 marks.";
    if (wantsFillBlanks && !hasFIB) return "You selected Fill in the Blanks but assigned 0 marks.";
    if (wantsShortQs && !hasShort) return "You selected Short Questions but assigned 0 marks across all fields.";
    if (wantsLongQs && !hasLong) return "You selected Long Questions but assigned 0 marks across all fields.";

    return null;
  }

  bool validateCustomQuestions() {
    if (!wantsCustomQuestions) return true;
    for (var q in customQuestions) {
      if (q.targetClo == null) return false;
      if (q.textCtrl.text.trim().isEmpty) return false;

      if (q.subParts.isEmpty && (double.tryParse(q.marksCtrl.text) ?? 0) <= 0) {
        return false;
      }

      if (q.subParts.isNotEmpty) {
        for (var sp in q.subParts) {
          // Check if marks are valid
          if ((double.tryParse(sp.marksCtrl.text) ?? 0) <= 0) {
            return false;
          }
          // BUG FIX: Only demand the hint text if AI generation is turned OFF
          if (!q.useAI && sp.hintCtrl.text.trim().isEmpty) {
            return false;
          }
        }
      }
    }
    return true;
  }

  bool validateScenarios() {
    if (!wantsScenariosOrCode) return true;
    for (var q in scenarioQuestions) {
      if (q.targetClo == null) return false;
      if (q.textCtrl.text.trim().isEmpty) return false;
      if (q.type == 'Code' && q.langCtrl.text.trim().isEmpty) return false;
      if ((int.tryParse(q.marksCtrl.text) ?? 0) <= 0) return false;
    }
    return true;
  }

  bool validateDiagrams() {
    if (!wantsDiagrams) return true;
    for (int i = 0; i < diagramTextControllers.length; i++) {
      if (diagramTargetCLOs[i] == null) return false;
      if (diagramImages[i] == null) return false;
      if (diagramTextControllers[i].text.trim().isEmpty) return false;
      if ((int.tryParse(diagramMarksControllers[i].text) ?? 0) <= 0)
        return false;
    }
    return true;
  }

  // --- GENERATION EXECUTION ---

  Future<Map<String, dynamic>?> _uploadImageToSupabase(File imageFile, BuildContext context) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileSizeBytes = await imageFile.length();
      final fileName = 'diagram_${DateTime.now().millisecondsSinceEpoch}.png';
      final url = await _assessmentRepo.uploadDiagram(fileName, imageFile);
      return {'url': url, 'file_name': fileName, 'size_bytes': fileSizeBytes};
    } catch (e) {
      return null;
    }
  }

  Future<void> triggerGeneration(BuildContext context) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final historyResponse = await _assessmentRepo.fetchUserAssessments(userId);

      if (historyResponse.length >= 10) {
        if (!context.mounted) return;
        bool? shouldDelete = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text("History Limit Reached"),
            content: const Text(
              "Maximum limit of 10 saved exams reached. Delete the oldest exam to proceed?",
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  "Delete & Continue",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (shouldDelete != true) return;

        final oldestExam = historyResponse.first;
        final Map<String, dynamic> oldData = oldestExam['content'];
        final List<dynamic>? oldDiagrams = oldData['diagram_questions'];
        int bytesToFree = 0;

        if (oldDiagrams != null && oldDiagrams.isNotEmpty) {
          for (var diag in oldDiagrams) {
            String? exactFileName =
                diag['file_name'] ??
                    (diag['image_url'] as String?)?.split('/').last.split('?').first;
            if (exactFileName != null) {
              await _assessmentRepo.deleteDiagrams([exactFileName]);
              bytesToFree += (diag['size_bytes'] as int?) ?? (800 * 1024);
            }
          }
        }
        await _assessmentRepo.deleteAssessment(oldestExam['id']);
        if (bytesToFree > 0) {
          await _assessmentRepo.incrementStorage(userId, -bytesToFree);
          if (context.mounted) {
            context.read<AuthViewModel>().adjustStorageLocal(-bytesToFree);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Utils.showSnackBar(context, "Failed to verify history limits.", Colors.redAccent);
      }
      return;
    }

    List<Map<String, dynamic>> processedDiagramQuestions = [];
    if (wantsDiagrams) {
      for (int i = 0; i < diagramTextControllers.length; i++) {
        String text = diagramTextControllers[i].text.trim();
        File? imageFile = diagramImages[i];

        if (text.isNotEmpty && imageFile != null) {
          if (context.mounted) {
            Utils.showSnackBar(context, "Uploading Diagram #${i + 1} to cloud...", Colors.blueAccent);
          }
          try {
            Map<String, dynamic>? uploadData = await _uploadImageToSupabase(imageFile, context);
            if (uploadData != null) {
              processedDiagramQuestions.add({
                "question": text,
                "marks": double.tryParse(diagramMarksControllers[i].text.trim()) ?? 5.0,
                "image_url": uploadData['url'],
                "file_name": uploadData['file_name'],
                "size_bytes": uploadData['size_bytes'],
                "target_clo": diagramTargetCLOs[i],
              });
            } else {
              Utils.showSnackBar(context, "Upload Failed.", Colors.redAccent);
              return;
            }
          } catch (e) {
            if (context.mounted) Utils.showSnackBar(context, "Upload Error: $e", Colors.redAccent);
            return;
          }
        }
      }
    }

    _setLoading(true);

    try {
      String? combinedText = await _documentRepo.extractTextFromFiles(_selectedFiles);
      if (combinedText == null || combinedText.trim().isEmpty) {
        _setLoading(false);
        if (context.mounted) {
          Utils.showSnackBar(context, "Could not extract text. Please check files.", Colors.redAccent);
        }
        return;
      }
      _lastDocumentText = combinedText;

      StringBuffer blueprint = StringBuffer();

      for (int i = 0; i < importedCLOs.length; i++) {
        var clo = importedCLOs[i];
        if (clo['isSelected'] == true) {
          String cloName = "CLO ${i + 1}";
          blueprint.writeln(
            "[$cloName: ${clo['description']}] (BT Level: ${clo['bt_level']})",
          );

          if (wantsMCQs && !randomMCQs) {
            double qty = double.tryParse(clo['mcq_qty'].text) ?? 0;
            double marks = double.tryParse(clo['mcq_marks'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- MCQs: ${qty.toInt()} ($marks marks each)");
          }
          if (wantsFillBlanks && !randomFillBlanks) {
            double qty = double.tryParse(clo['fib_qty'].text) ?? 0;
            double marks = double.tryParse(clo['fib_marks'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- Fill in the Blanks: ${qty.toInt()} ($marks marks each)");
          }
          if (wantsShortQs && !randomShortQs) {
            double qty = double.tryParse(clo['short_qty'].text) ?? 0;
            double marks = double.tryParse(clo['short_marks'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- Short Questions: ${qty.toInt()} ($marks marks each)");
          }
          if (wantsLongQs && !randomLongQs) {
            double qty = double.tryParse(clo['long_qty'].text) ?? 0;
            double marks = double.tryParse(clo['long_marks'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- Long Questions: ${qty.toInt()} ($marks marks each)");
          }
          blueprint.writeln("");
        }
      }

      if ((wantsMCQs && randomMCQs) ||
          (wantsFillBlanks && randomFillBlanks) ||
          (wantsShortQs && randomShortQs) ||
          (wantsLongQs && randomLongQs)) {
        blueprint.writeln("[RANDOMIZED GLOBAL POOL]");
        blueprint.writeln("Distribute the following question quantities randomly across the available CLOs:");
        if (wantsMCQs && randomMCQs) {
          blueprint.writeln("- MCQs: ${globalMcqQtyCtrl.text} (${globalMcqMarksCtrl.text} marks each)");
        }
        if (wantsFillBlanks && randomFillBlanks) {
          blueprint.writeln("- Fill in the Blanks: ${globalFibQtyCtrl.text} (${globalFibMarksCtrl.text} marks each)");
        }
        if (wantsShortQs && randomShortQs) {
          blueprint.writeln("- Short Questions: ${globalShortQtyCtrl.text} (${globalShortMarksCtrl.text} marks each)");
        }
        if (wantsLongQs && randomLongQs) {
          blueprint.writeln("- Long Questions: ${globalLongQtyCtrl.text} (${globalLongMarksCtrl.text} marks each)");
        }
        blueprint.writeln("");
      }

      List<Map<String, dynamic>> combinedAdvancedList = [];

      if (wantsScenariosOrCode) {
        for (var q in scenarioQuestions) {
          if (q.textCtrl.text.trim().isNotEmpty) {
            combinedAdvancedList.add({
              "question": q.textCtrl.text.trim(),
              "marks": q.totalMarks,
              "type": q.type,
              "merge_category": q.mergeCategory,
              "language": q.langCtrl.text.trim(),
              "target_clo": q.targetClo,
              "use_ai": q.useAI,
              "sub_parts": [],
            });
          }
        }
      }

      if (wantsCustomQuestions) {
        for (var q in customQuestions) {
          if (q.textCtrl.text.trim().isNotEmpty) {
            List<Map<String, dynamic>> formattedSubParts = [];
            for (int i = 0; i < q.subParts.length; i++) {
              formattedSubParts.add({
                "label": String.fromCharCode(97 + i),
                "question": q.subParts[i].hintCtrl.text.trim(),
                "marks": double.tryParse(q.subParts[i].marksCtrl.text.trim()) ?? 0.0,
              });
            }


            String actualType = activeSubjectiveIngredientNames.contains(q.type)
                ? q.type
                : activeSubjectiveIngredientNames.first;

            combinedAdvancedList.add({
              "question": q.textCtrl.text.trim(),
              "marks": q.totalMarks,
              "type": actualType,
              "merge_category": actualType,
              "language": "",
              "target_clo": q.targetClo,
              "use_ai": q.useAI,
              "sub_parts": formattedSubParts,
            });
          }
        }
      }

      _generatedAssessment = await _geminiRepo.generateAssessment(
        documentText: combinedText,
        paperCategory: selectedPaperCategory,
        examBlueprint: blueprint.toString(),
        letAIGenerateScenario: true,
        customScenarios: combinedAdvancedList,
        diagramQuestions: processedDiagramQuestions,
        allowSubParts: true,
      );

      if (_generatedAssessment != null) {
        _generatedAssessment!['marks'] = {
          "mcq_points": wantsMCQs
              ? (randomMCQs
              ? double.tryParse(globalMcqMarksCtrl.text)
              : double.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['mcq_marks'].text : '1')) ?? 1.0
              : 0.0,
          "short_points": wantsShortQs
              ? (randomShortQs
              ? double.tryParse(globalShortMarksCtrl.text)
              : double.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['short_marks'].text : '3')) ?? 3.0
              : 0.0,
          "long_points": wantsLongQs
              ? (randomLongQs
              ? double.tryParse(globalLongMarksCtrl.text)
              : double.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['long_marks'].text : '5')) ?? 5.0
              : 0.0,
          "fib_points": wantsFillBlanks
              ? (randomFillBlanks
              ? double.tryParse(globalFibMarksCtrl.text)
              : double.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['fib_marks'].text : '1')) ?? 1.0
              : 0.0,
        };
        _generatedAssessment!['diagram_questions'] = processedDiagramQuestions;

        // BUG FIX: Completely merge BOTH Custom Questions AND Scenarios bypassing Gemini's hallucinated types
        if (_generatedAssessment!['custom_scenarios'] != null) {
          final scenarios = _generatedAssessment!['custom_scenarios'] as List;
          List<dynamic> remainingScenarios = [];

          for (int i = 0; i < scenarios.length; i++) {
            var sc = Map<String, dynamic>.from(scenarios[i]);

            // SAFELY Recover mapping directly from our local state, ignoring Gemini's output mapping
            String localType = 'Scenario';
            String localMergeCat = 'Stand-alone';

            if (i < combinedAdvancedList.length) {
              localType = combinedAdvancedList[i]['type']?.toString() ?? 'Scenario';
              localMergeCat = combinedAdvancedList[i]['merge_category']?.toString() ?? 'Stand-alone';
            }

            // Route based strictly on the Dropdown settings the user selected
            String routeTo = localMergeCat != 'Stand-alone' ? localMergeCat : localType;

            if (routeTo == 'Short Question') {
              _generatedAssessment!['shortQuestions'] ??= [];
              sc['idealAnswer'] = sc['idealAnswer'] ?? sc['question'] ?? sc['text'] ?? "Refer to source material.";
              sc.remove('type');
              sc.remove('merge_category');
              _generatedAssessment!['shortQuestions'].add(sc);

            } else if (routeTo == 'Long Question') {
              _generatedAssessment!['longQuestions'] ??= [];
              sc['gradingRubric'] = sc['gradingRubric'] ?? sc['idealAnswer'] ?? sc['question'] ?? sc['text'] ?? "Refer to source material.";
              sc.remove('type');
              sc.remove('merge_category');
              _generatedAssessment!['longQuestions'].add(sc);

            } else {
              sc['type'] = localType; // Preserve 'Scenario' or 'Code' label for UI if it's genuinely Stand-alone
              remainingScenarios.add(sc);
            }
          }
          // Anything properly mapped to Short/Long is now permanently deleted from custom_scenarios
          _generatedAssessment!['custom_scenarios'] = remainingScenarios;
        }

        if (context.mounted) {
          await context.read<HistoryViewModel>().saveAssessment(_generatedAssessment!);
        }
      }

      _setLoading(false);

      if (_generatedAssessment != null && context.mounted) {
        Utils.showSnackBar(context, "Assessment Generated Successfully!", Colors.green);
      } else {
        if (context.mounted) {
          Utils.showSnackBar(context, "AI failed to generate. Check your API key limit.", Colors.redAccent);
        }
      }
    } catch (e, stacktrace) {
      _setLoading(false);
      debugPrint("Generation Error: $e\n$stacktrace");
      if (context.mounted) {
        Utils.showSnackBar(context, e.toString().replaceAll('Exception:', '').trim(), Colors.redAccent);
      }
    }
  }

  // Future<void> triggerGeneration(BuildContext context) async {
  //   try {
  //     final userId = Supabase.instance.client.auth.currentUser!.id;
  //     final historyResponse = await _assessmentRepo.fetchUserAssessments(
  //       userId,
  //     );
  //
  //     if (historyResponse.length >= 10) {
  //       if (!context.mounted) return;
  //       bool? shouldDelete = await showDialog<bool>(
  //         context: context,
  //         barrierDismissible: false,
  //         builder: (dialogContext) => AlertDialog(
  //           title: const Text("History Limit Reached"),
  //           content: const Text(
  //             "Maximum limit of 10 saved exams reached. Delete the oldest exam to proceed?",
  //           ),
  //           actions: [
  //             TextButton(
  //               child: const Text("Cancel"),
  //               onPressed: () => Navigator.of(dialogContext).pop(false),
  //             ),
  //             ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.redAccent,
  //               ),
  //               onPressed: () => Navigator.of(dialogContext).pop(true),
  //               child: const Text(
  //                 "Delete & Continue",
  //                 style: TextStyle(color: Colors.white),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //
  //       if (shouldDelete != true) return;
  //
  //       final oldestExam = historyResponse.first;
  //       final Map<String, dynamic> oldData = oldestExam['content'];
  //       final List<dynamic>? oldDiagrams = oldData['diagram_questions'];
  //       int bytesToFree = 0;
  //
  //       if (oldDiagrams != null && oldDiagrams.isNotEmpty) {
  //         for (var diag in oldDiagrams) {
  //           String? exactFileName =
  //               diag['file_name'] ??
  //               (diag['image_url'] as String?)
  //                   ?.split('/')
  //                   .last
  //                   .split('?')
  //                   .first;
  //           if (exactFileName != null) {
  //             await _assessmentRepo.deleteDiagrams([exactFileName]);
  //             bytesToFree += (diag['size_bytes'] as int?) ?? (800 * 1024);
  //           }
  //         }
  //       }
  //       await _assessmentRepo.deleteAssessment(oldestExam['id']);
  //       if (bytesToFree > 0) {
  //         await _assessmentRepo.incrementStorage(userId, -bytesToFree);
  //         if (context.mounted)
  //           context.read<AuthViewModel>().adjustStorageLocal(-bytesToFree);
  //       }
  //     }
  //   } catch (e) {
  //     if (context.mounted)
  //       Utils.showSnackBar(
  //         context,
  //         "Failed to verify history limits.",
  //         Colors.redAccent,
  //       );
  //     return;
  //   }
  //
  //   List<Map<String, dynamic>> processedDiagramQuestions = [];
  //   if (wantsDiagrams) {
  //     for (int i = 0; i < diagramTextControllers.length; i++) {
  //       String text = diagramTextControllers[i].text.trim();
  //       File? imageFile = diagramImages[i];
  //
  //       if (text.isNotEmpty && imageFile != null) {
  //         if (context.mounted)
  //           Utils.showSnackBar(
  //             context,
  //             "Uploading Diagram #${i + 1} to cloud...",
  //             Colors.blueAccent,
  //           );
  //         try {
  //           Map<String, dynamic>? uploadData = await _uploadImageToSupabase(
  //             imageFile,
  //             context,
  //           );
  //           if (uploadData != null) {
  //             processedDiagramQuestions.add({
  //               "question": text,
  //               "marks":
  //                   int.tryParse(diagramMarksControllers[i].text.trim()) ?? 5,
  //               "image_url": uploadData['url'],
  //               "file_name": uploadData['file_name'],
  //               "size_bytes": uploadData['size_bytes'],
  //               "target_clo": diagramTargetCLOs[i],
  //             });
  //           } else {
  //             Utils.showSnackBar(context, "Upload Failed.", Colors.redAccent);
  //             return;
  //           }
  //         } catch (e) {
  //           if (context.mounted)
  //             Utils.showSnackBar(context, "Upload Error: $e", Colors.redAccent);
  //           return;
  //         }
  //       }
  //     }
  //   }
  //
  //   _setLoading(true);
  //
  //   try {
  //     String? combinedText = await _documentRepo.extractTextFromFiles(
  //       _selectedFiles,
  //     );
  //     if (combinedText == null || combinedText.trim().isEmpty) {
  //       _setLoading(false);
  //       if (context.mounted)
  //         Utils.showSnackBar(
  //           context,
  //           "Could not extract text. Please check files.",
  //           Colors.redAccent,
  //         );
  //       return;
  //     }
  //     _lastDocumentText = combinedText;
  //
  //     StringBuffer blueprint = StringBuffer();
  //
  //     for (int i = 0; i < importedCLOs.length; i++) {
  //       var clo = importedCLOs[i];
  //       if (clo['isSelected'] == true) {
  //         String cloName = "CLO ${i + 1}";
  //         blueprint.writeln(
  //           "[$cloName: ${clo['description']}] (BT Level: ${clo['bt_level']})",
  //         );
  //
  //         if (wantsMCQs && !randomMCQs) {
  //           int qty = int.tryParse(clo['mcq_qty'].text) ?? 0;
  //           if (qty > 0) blueprint.writeln("- MCQs: $qty");
  //         }
  //         if (wantsFillBlanks && !randomFillBlanks) {
  //           int qty = int.tryParse(clo['fib_qty'].text) ?? 0;
  //           if (qty > 0) blueprint.writeln("- Fill in the Blanks: $qty");
  //         }
  //         if (wantsShortQs && !randomShortQs) {
  //           int qty = int.tryParse(clo['short_qty'].text) ?? 0;
  //           if (qty > 0) blueprint.writeln("- Short Questions: $qty");
  //         }
  //         if (wantsLongQs && !randomLongQs) {
  //           int qty = int.tryParse(clo['long_qty'].text) ?? 0;
  //           if (qty > 0) blueprint.writeln("- Long Questions: $qty");
  //         }
  //         blueprint.writeln("");
  //       }
  //     }
  //
  //     if ((wantsMCQs && randomMCQs) ||
  //         (wantsFillBlanks && randomFillBlanks) ||
  //         (wantsShortQs && randomShortQs) ||
  //         (wantsLongQs && randomLongQs)) {
  //       blueprint.writeln("[RANDOMIZED GLOBAL POOL]");
  //       blueprint.writeln(
  //         "Distribute the following question quantities randomly across the available CLOs:",
  //       );
  //       if (wantsMCQs && randomMCQs) {
  //         int qty = int.tryParse(globalMcqQtyCtrl.text) ?? 0;
  //         if (qty > 0) blueprint.writeln("- MCQs: $qty");
  //       }
  //       if (wantsFillBlanks && randomFillBlanks) {
  //         int qty = int.tryParse(globalFibQtyCtrl.text) ?? 0;
  //         if (qty > 0) blueprint.writeln("- Fill in the Blanks: $qty");
  //       }
  //       if (wantsShortQs && randomShortQs) {
  //         int qty = int.tryParse(globalShortQtyCtrl.text) ?? 0;
  //         if (qty > 0) blueprint.writeln("- Short Questions: $qty");
  //       }
  //       if (wantsLongQs && randomLongQs) {
  //         int qty = int.tryParse(globalLongQtyCtrl.text) ?? 0;
  //         if (qty > 0) blueprint.writeln("- Long Questions: $qty");
  //       }
  //       blueprint.writeln("");
  //     }
  //
  //     List<Map<String, dynamic>> combinedAdvancedList = [];
  //
  //     if (wantsScenariosOrCode) {
  //       for (var q in scenarioQuestions) {
  //         if (q.textCtrl.text.trim().isNotEmpty) {
  //           combinedAdvancedList.add({
  //             "text": q.textCtrl.text.trim(),
  //             "marks": q.totalMarks,
  //             "type": q.type,
  //             "language": q.langCtrl.text.trim(),
  //             "target_clo": q.targetClo,
  //             "use_ai": q.useAI, // NEW: Include scenario AI flag
  //             "sub_parts": [],
  //           });
  //         }
  //       }
  //       if (context.mounted) {
  //         await context.read<HistoryViewModel>().saveAssessment(
  //           _generatedAssessment!,
  //         );
  //       }
  //     }
  //
  //     if (wantsCustomQuestions) {
  //       for (var q in customQuestions) {
  //         if (q.textCtrl.text.trim().isNotEmpty) {
  //           List<Map<String, dynamic>> formattedSubParts = [];
  //           for (int i = 0; i < q.subParts.length; i++) {
  //             formattedSubParts.add({
  //               "label": String.fromCharCode(97 + i),
  //               "question": q.subParts[i].hintCtrl.text.trim(),
  //               "marks": double.tryParse(q.subParts[i].marksCtrl.text.trim()) ?? 0.0, // <-- Changed to double
  //             });
  //           }
  //
  //           combinedAdvancedList.add({
  //             "text": q.textCtrl.text.trim(),
  //             "marks": q.totalMarks,
  //             "type": q.type,
  //             "language": "",
  //             "target_clo": q.targetClo,
  //             "use_ai": q.useAI,
  //             "sub_parts": formattedSubParts,
  //           });
  //         }
  //       }
  //     }
  //
  //     _generatedAssessment = await _geminiRepo.generateAssessment(
  //       documentText: combinedText,
  //       paperCategory: selectedPaperCategory,
  //       examBlueprint: blueprint.toString(),
  //       letAIGenerateScenario: true,
  //       customScenarios: combinedAdvancedList,
  //       diagramQuestions: processedDiagramQuestions,
  //       allowSubParts: true,
  //     );
  //
  //     if (_generatedAssessment != null) {
  //       _generatedAssessment!['marks'] = {
  //         "mcq_points": wantsMCQs
  //             ? (randomMCQs
  //                       ? int.tryParse(globalMcqMarksCtrl.text)
  //                       : int.tryParse(
  //                           importedCLOs.isNotEmpty
  //                               ? importedCLOs[0]['mcq_marks'].text
  //                               : '1',
  //                         )) ??
  //                   1
  //             : 0,
  //         "short_points": wantsShortQs
  //             ? (randomShortQs
  //                       ? int.tryParse(globalShortMarksCtrl.text)
  //                       : int.tryParse(
  //                           importedCLOs.isNotEmpty
  //                               ? importedCLOs[0]['short_marks'].text
  //                               : '3',
  //                         )) ??
  //                   3
  //             : 0,
  //         "long_points": wantsLongQs
  //             ? (randomLongQs
  //                       ? int.tryParse(globalLongMarksCtrl.text)
  //                       : int.tryParse(
  //                           importedCLOs.isNotEmpty
  //                               ? importedCLOs[0]['long_marks'].text
  //                               : '5',
  //                         )) ??
  //                   5
  //             : 0,
  //         "fib_points": wantsFillBlanks
  //             ? (randomFillBlanks
  //                       ? int.tryParse(globalFibMarksCtrl.text)
  //                       : int.tryParse(
  //                           importedCLOs.isNotEmpty
  //                               ? importedCLOs[0]['fib_marks'].text
  //                               : '1',
  //                         )) ??
  //                   1
  //             : 0,
  //       };
  //       _generatedAssessment!['diagram_questions'] = processedDiagramQuestions;
  //
  //       if (_generatedAssessment!['custom_scenarios'] != null) {
  //         final scenarios = _generatedAssessment!['custom_scenarios'] as List;
  //         for (int i = 0; i < scenarios.length; i++) {
  //           if (i < combinedAdvancedList.length)
  //             scenarios[i]['type'] =
  //                 scenarios[i]['type'] ?? combinedAdvancedList[i]['type'];
  //         }
  //       }
  //     }
  //
  //     _setLoading(false);
  //
  //     if (_generatedAssessment != null && context.mounted) {
  //       Utils.showSnackBar(
  //         context,
  //         "Assessment Generated Successfully!",
  //         Colors.green,
  //       );
  //     } else {
  //       if (context.mounted)
  //         Utils.showSnackBar(
  //           context,
  //           "AI failed to generate. Check your API key limit.",
  //           Colors.redAccent,
  //         );
  //     }
  //   } catch (e, stacktrace) {
  //     _setLoading(false);
  //     debugPrint("Generation Error: $e\n$stacktrace");
  //     if (context.mounted)
  //       Utils.showSnackBar(
  //         context,
  //         e.toString().replaceAll('Exception:', '').trim(),
  //         Colors.redAccent,
  //       );
  //   }
  // }

  void loadPastAssessment(Map<String, dynamic> pastData) {
    _generatedAssessment = pastData;
    notifyListeners();
  }

  Future<void> clearData() async {
    _selectedFiles.clear();
    _generatedAssessment = null;
    _isLoading = false;
    _lastDocumentText = "";
    _regeneratingItems.clear();

    globalMcqQtyCtrl.clear();
    globalMcqMarksCtrl.clear();
    globalFibQtyCtrl.clear();
    globalFibMarksCtrl.clear();
    globalShortQtyCtrl.clear();
    globalShortMarksCtrl.clear();
    globalLongQtyCtrl.clear();
    globalLongMarksCtrl.clear();

    clearImportedCourse();

    wantsMCQs = false;
    wantsFillBlanks = false;
    wantsShortQs = false;
    wantsLongQs = false;
    wantsScenariosOrCode = false;
    wantsDiagrams = false;
    wantsCustomQuestions = false;
    randomMCQs = false;
    randomFillBlanks = false;
    randomShortQs = false;
    randomLongQs = false;

    for (var q in scenarioQuestions) q.dispose();
    scenarioQuestions.clear();
    _addScenarioQuestionSilent();

    for (var q in customQuestions) q.dispose();
    customQuestions.clear();
    _addCustomQuestionSilent();

    final prefs = await SharedPreferences.getInstance();
    await _clearDraftFromMemory(prefs);
    notifyListeners();
  }

  void _attachSaveListeners() {
    globalMcqQtyCtrl.addListener(_onFormChanged);
    globalMcqMarksCtrl.addListener(_onFormChanged);
    globalFibQtyCtrl.addListener(_onFormChanged);
    globalFibMarksCtrl.addListener(_onFormChanged);
    globalShortQtyCtrl.addListener(_onFormChanged);
    globalShortMarksCtrl.addListener(_onFormChanged);
    globalLongQtyCtrl.addListener(_onFormChanged);
    globalLongMarksCtrl.addListener(_onFormChanged);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'draft_last_active',
      DateTime.now().toIso8601String(),
    );
    await prefs.setString('draft_category', selectedPaperCategory);

    await prefs.setBool('draft_wants_mcq', wantsMCQs);
    await prefs.setBool('draft_wants_fib', wantsFillBlanks);
    await prefs.setBool('draft_wants_short', wantsShortQs);
    await prefs.setBool('draft_wants_long', wantsLongQs);
    await prefs.setBool('draft_wants_scenario', wantsScenariosOrCode);
    await prefs.setBool('draft_wants_custom', wantsCustomQuestions);
    await prefs.setBool('draft_wants_diagram', wantsDiagrams);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString('draft_last_active');

    if (lastActiveStr != null) {
      final lastActiveTime = DateTime.parse(lastActiveStr);
      final minutesSinceActive = DateTime.now()
          .difference(lastActiveTime)
          .inMinutes;

      if (minutesSinceActive > _draftExpirationMinutes) {
        await _clearDraftFromMemory(prefs);
        return;
      }
      selectedPaperCategory =
          prefs.getString('draft_category') ?? 'Theory Based';

      wantsMCQs = prefs.getBool('draft_wants_mcq') ?? false;
      wantsFillBlanks = prefs.getBool('draft_wants_fib') ?? false;
      wantsShortQs = prefs.getBool('draft_wants_short') ?? false;
      wantsLongQs = prefs.getBool('draft_wants_long') ?? false;
      wantsScenariosOrCode = prefs.getBool('draft_wants_scenario') ?? false;
      wantsCustomQuestions = prefs.getBool('draft_wants_custom') ?? false;
      wantsDiagrams = prefs.getBool('draft_wants_diagram') ?? false;

      notifyListeners();
    }
  }

  Future<void> _clearDraftFromMemory(SharedPreferences prefs) async {
    await prefs.remove('draft_last_active');
    await prefs.remove('draft_category');
    await prefs.remove('draft_wants_mcq');
    await prefs.remove('draft_wants_fib');
    await prefs.remove('draft_wants_short');
    await prefs.remove('draft_wants_long');
    await prefs.remove('draft_wants_scenario');
    await prefs.remove('draft_wants_custom');
    await prefs.remove('draft_wants_diagram');
  }

  @override
  void dispose() {
    globalMcqQtyCtrl.dispose();
    globalMcqMarksCtrl.dispose();
    globalFibQtyCtrl.dispose();
    globalFibMarksCtrl.dispose();
    globalShortQtyCtrl.dispose();
    globalShortMarksCtrl.dispose();
    globalLongQtyCtrl.dispose();
    globalLongMarksCtrl.dispose();
    for (var q in scenarioQuestions) q.  dispose();
    for (var q in customQuestions) q.dispose();
    super.dispose();
  }
}
