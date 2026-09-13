import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_view_model.dart';
import '../repository/assessment_repository.dart';
import '../repository/document_repository.dart';
import '../repository/gemini_repository.dart';
import '../utils/utils.dart';

// --- CLEAN STATE CLASSES FOR ADVANCED BUILDER ---
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
  String type = 'Scenario';
  String? targetClo;
  List<AdvancedSubPartState> subParts = [];

  void dispose() {
    textCtrl.dispose();
    marksCtrl.dispose();
    langCtrl.dispose();
    for (var sp in subParts) {
      sp.dispose();
    }
  }

  int get totalMarks {
    if (subParts.isEmpty) {
      return int.tryParse(marksCtrl.text) ?? 0;
    } else {
      return subParts.fold(0, (sum, part) => sum + (int.tryParse(part.marksCtrl.text) ?? 0));
    }
  }
}
// -----------------------------------------------------

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

  bool wantsMCQs = false;
  bool randomMCQs = false;
  bool wantsFillBlanks = false;
  bool randomFillBlanks = false;
  bool wantsShortQs = false;
  bool randomShortQs = false;
  bool wantsLongQs = false;
  bool randomLongQs = false;
  bool wantsScenariosOrCode = false;
  bool wantsDiagrams = false;

  bool get hasSelectedIngredients =>
      wantsMCQs || wantsFillBlanks || wantsShortQs || wantsLongQs || wantsScenariosOrCode || wantsDiagrams;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> get departments => _departments;

  Map<String, dynamic>? _generalDepartment;
  Map<String, dynamic>? get generalDepartment => _generalDepartment;

  List<Map<String, dynamic>> _availableBatches = [];
  Map<String, dynamic>? _selectedBatch;
  List<Map<String, dynamic>> get availableBatches => _availableBatches;
  Map<String, dynamic>? get selectedBatch => _selectedBatch;

  List<Map<String, dynamic>> _filteredMasterCourses = [];
  List<Map<String, dynamic>> get filteredMasterCourses => _filteredMasterCourses;

  String selectedPaperCategory = 'Theory Based';
  bool letAIGenerateScenario = true;

  // Global Random Controllers
  final TextEditingController globalMcqQtyCtrl = TextEditingController();
  final TextEditingController globalMcqMarksCtrl = TextEditingController();
  final TextEditingController globalFibQtyCtrl = TextEditingController();
  final TextEditingController globalFibMarksCtrl = TextEditingController();
  final TextEditingController globalShortQtyCtrl = TextEditingController();
  final TextEditingController globalShortMarksCtrl = TextEditingController();
  final TextEditingController globalLongQtyCtrl = TextEditingController();
  final TextEditingController globalLongMarksCtrl = TextEditingController();

  // Advanced Question Builder State
  List<AdvancedQuestionState> advancedQuestions = [];

  // Diagrams State
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
  bool isRegenerating(String type, int index) => _regeneratingItems.contains("${type}_$index");

  AssessmentViewModel() {
    _loadDraft();
    _attachSaveListeners();
    if (advancedQuestions.isEmpty) _addAdvancedQuestionSilent();
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
      case 'diagram':
        wantsDiagrams = value;
        break;
    }
    _onFormChanged();
  }

  void toggleRandomIngredient(String type, bool? value) {
    if (value == null) return;
    switch (type) {
      case 'mcq': randomMCQs = value; break;
      case 'fib': randomFillBlanks = value; break;
      case 'short': randomShortQs = value; break;
      case 'long': randomLongQs = value; break;
    }
    _onFormChanged();
  }

  Future<void> fetchDepartments() async {
    try {
      _departments = await _assessmentRepo.fetchDepartments();
      try {
        _generalDepartment = _departments.firstWhere((dept) => dept['name'].toString().contains('General'));
      } catch (e) {
        debugPrint("General department not found.");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching departments: $e");
    }
  }

  Future<void> fetchBatches() async {
    try {
      _availableBatches = await _assessmentRepo.fetchBatches();
      if (_availableBatches.isNotEmpty) _selectedBatch ??= _availableBatches.first;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching batches: $e");
    }
  }

  Future<bool> createNewBatch(int startYear, int endYear) async {
    try {
      final bool alreadyExists = _availableBatches.any((batch) => batch['start_year'] == startYear && batch['end_year'] == endYear);
      if (alreadyExists) return false;

      final String batchName = "Session $startYear-$endYear";
      final newBatch = await _assessmentRepo.createNewBatch(startYear, endYear, batchName);

      _availableBatches.add(newBatch);
      _availableBatches.sort((a, b) => (b['start_year'] as int).compareTo(a['start_year'] as int));
      _selectedBatch = newBatch;
      notifyListeners();
      fetchCoursesForSelectedBatch();
      return true;
    } catch (e) {
      debugPrint("Error creating new batch: $e");
      return false;
    }
  }

  Future<void> fetchCoursesForSelectedBatch() async {
    if (_selectedBatch == null) return;
    try {
      _filteredMasterCourses = await _assessmentRepo.fetchCoursesByBatch(_selectedBatch!['id']);
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading courses: $e");
    }
  }

  void updateSelectedBatch(Map<String, dynamic>? newBatch) {
    if (newBatch != null) {
      _selectedBatch = newBatch;
      notifyListeners();
      fetchCoursesForSelectedBatch();
    }
  }

  void setImportedCourse(String code, String title, List<Map<String, dynamic>> clos, String creditHours, String departmentName) {
    selectedCourseCode = code;
    selectedCourseTitle = title;
    selectedDepartmentName = departmentName;

    importedCLOs = clos.map((clo) {
      final modifiableClo = Map<String, dynamic>.from(clo);
      modifiableClo['isSelected'] = true;

      modifiableClo['mcq_qty'] = TextEditingController();
      modifiableClo['mcq_marks'] = TextEditingController();
      modifiableClo['fib_qty'] = TextEditingController();
      modifiableClo['fib_marks'] = TextEditingController();
      modifiableClo['short_qty'] = TextEditingController();
      modifiableClo['short_marks'] = TextEditingController();
      modifiableClo['long_qty'] = TextEditingController();
      modifiableClo['long_marks'] = TextEditingController();

      (modifiableClo['mcq_qty'] as TextEditingController).addListener(_onFormChanged);
      (modifiableClo['mcq_marks'] as TextEditingController).addListener(_onFormChanged);
      (modifiableClo['fib_qty'] as TextEditingController).addListener(_onFormChanged);
      (modifiableClo['fib_marks'] as TextEditingController).addListener(_onFormChanged);
      (modifiableClo['short_qty'] as TextEditingController).addListener(_onFormChanged);
      (modifiableClo['short_marks'] as TextEditingController).addListener(_onFormChanged);
      (modifiableClo['long_qty'] as TextEditingController).addListener(_onFormChanged);
      (modifiableClo['long_marks'] as TextEditingController).addListener(_onFormChanged);

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

      if (!hasPractical && selectedExamType == 'Practical') {
        selectedExamType = 'Mid-Term';
      }
      notifyListeners();
    }
  }

  void setExamType(String type) {
    selectedExamType = type;
    notifyListeners();
  }

  int get currentTargetMarks {
    if (selectedExamType == 'Mid-Term') return midTermTarget;
    if (selectedExamType == 'Final') return finalTermTarget;
    if (selectedExamType == 'Practical') return practicalTarget;
    return 0;
  }

  int get currentConfiguredMarks {
    int total = 0;

    for (var clo in importedCLOs) {
      if (clo['isSelected'] == true) {
        if (wantsMCQs && !randomMCQs) total += (int.tryParse(clo['mcq_qty'].text) ?? 0) * (int.tryParse(clo['mcq_marks'].text) ?? 0);
        if (wantsFillBlanks && !randomFillBlanks) total += (int.tryParse(clo['fib_qty'].text) ?? 0) * (int.tryParse(clo['fib_marks'].text) ?? 0);
        if (wantsShortQs && !randomShortQs) total += (int.tryParse(clo['short_qty'].text) ?? 0) * (int.tryParse(clo['short_marks'].text) ?? 0);
        if (wantsLongQs && !randomLongQs) total += (int.tryParse(clo['long_qty'].text) ?? 0) * (int.tryParse(clo['long_marks'].text) ?? 0);
      }
    }

    if (wantsMCQs && randomMCQs) total += (int.tryParse(globalMcqQtyCtrl.text) ?? 0) * (int.tryParse(globalMcqMarksCtrl.text) ?? 0);
    if (wantsFillBlanks && randomFillBlanks) total += (int.tryParse(globalFibQtyCtrl.text) ?? 0) * (int.tryParse(globalFibMarksCtrl.text) ?? 0);
    if (wantsShortQs && randomShortQs) total += (int.tryParse(globalShortQtyCtrl.text) ?? 0) * (int.tryParse(globalShortMarksCtrl.text) ?? 0);
    if (wantsLongQs && randomLongQs) total += (int.tryParse(globalLongQtyCtrl.text) ?? 0) * (int.tryParse(globalLongMarksCtrl.text) ?? 0);

    if (wantsScenariosOrCode) {
      for (var q in advancedQuestions) {
        total += q.totalMarks;
      }
    }

    if (wantsDiagrams) {
      for (var ctrl in diagramMarksControllers) total += int.tryParse(ctrl.text) ?? 0;
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

  void toggleAIGenerateScenario(bool? value) {
    if (value != null) {
      letAIGenerateScenario = value;
      _onFormChanged();
    }
  }

  void updatePaperCategory(String? newValue) {
    if (newValue != null) {
      selectedPaperCategory = newValue;
      _onFormChanged();
    }
  }

  // --- ADVANCED QUESTION BUILDER METHODS ---
  void _addAdvancedQuestionSilent() {
    final q = AdvancedQuestionState();
    q.textCtrl.addListener(_onFormChanged);
    q.marksCtrl.addListener(_onFormChanged);
    q.langCtrl.addListener(_onFormChanged);
    advancedQuestions.add(q);
  }

  void addAdvancedQuestion() {
    _addAdvancedQuestionSilent();
    _onFormChanged();
  }

  void removeAdvancedQuestion(int index) {
    if (advancedQuestions.length > 1) {
      advancedQuestions[index].dispose();
      advancedQuestions.removeAt(index);
      _onFormChanged();
    }
  }

  void updateAdvancedQuestionType(int index, String newType) {
    advancedQuestions[index].type = newType;
    _onFormChanged();
  }

  void updateAdvancedQuestionClo(int index, String? newClo) {
    advancedQuestions[index].targetClo = newClo;
    _onFormChanged();
  }

  void addSubPartToQuestion(int questionIndex) {
    final sp = AdvancedSubPartState();
    sp.hintCtrl.addListener(_onFormChanged);
    sp.marksCtrl.addListener(_onFormChanged);
    advancedQuestions[questionIndex].subParts.add(sp);

    if (advancedQuestions[questionIndex].subParts.length == 1) {
      advancedQuestions[questionIndex].marksCtrl.clear();
    }
    _onFormChanged();
  }

  void removeSubPartFromQuestion(int questionIndex, int subPartIndex) {
    advancedQuestions[questionIndex].subParts[subPartIndex].dispose();
    advancedQuestions[questionIndex].subParts.removeAt(subPartIndex);
    _onFormChanged();
  }

  void addDiagramQuestion() {
    final marksCtrl = TextEditingController(text: "5");
    marksCtrl.addListener(_onFormChanged);
    diagramTextControllers.add(TextEditingController());
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
      final XFile? image = await picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        diagramImages[index] = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking diagram: $e");
    }
  }

  Future<void> pickFile(BuildContext context) async {
    if (!canAddMoreFiles) {
      Utils.showSnackBar(context, "You can only upload up to $maxFiles files at a time.", Colors.redAccent);
      return;
    }
    try {
      List<PlatformFile> files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx', 'pptx']) ?? [];
      if (files.isNotEmpty) {
        for (var file in files) {
          if (_selectedFiles.any((existing) => existing.name == file.name)) continue;
          if ((file.path != null ? File(file.path!).lengthSync() : 0) > maxFileSizeInBytes) continue;
          if (_selectedFiles.length >= maxFiles) break;
          _selectedFiles.add(file);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void removeFile(PlatformFile fileToRemove) {
    _selectedFiles.removeWhere((file) => file.name == fileToRemove.name);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> extractCourseWithGemini(XFile imageFile) async {
    return await _geminiRepo.extractCourseSyllabusFromImage(File(imageFile.path));
  }

  Future<void> regenerateSingleItem(BuildContext context, String type, int index) async {
    if (_lastDocumentText.isEmpty) {
      Utils.showSnackBar(context, "Context lost. Please generate a new assessment.", Colors.redAccent);
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
        if (context.mounted) Utils.showSnackBar(context, "Failed to regenerate question.", Colors.redAccent);
      }
    } catch (e) {
      if (context.mounted) Utils.showSnackBar(context, e.toString().replaceAll('Exception:', '').trim(), Colors.redAccent);
    }

    _regeneratingItems.remove(itemKey);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _uploadImageToSupabase(File imageFile, BuildContext context) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileSizeBytes = await imageFile.length();
      final profileResponse = await _assessmentRepo.fetchProfileStorage(userId);

      final int usedBytes = profileResponse['storage_used_bytes'] ?? 0;
      final int limitBytes = profileResponse['storage_limit_bytes'] ?? 52428800;

      if (usedBytes + fileSizeBytes > limitBytes) {
        if (context.mounted) Utils.showSnackBar(context, "Storage Limit Reached! Please upgrade or delete old assessments.", Colors.redAccent);
        return null;
      }

      final fileName = 'diagram_${DateTime.now().millisecondsSinceEpoch}.png';
      final url = await _assessmentRepo.uploadDiagram(fileName, imageFile);
      await _assessmentRepo.incrementStorage(userId, fileSizeBytes);

      if (context.mounted) {
        context.read<AuthViewModel>().adjustStorageLocal(fileSizeBytes);
      }
      return {'url': url, 'file_name': fileName, 'size_bytes': fileSizeBytes};
    } catch (e) {
      debugPrint("Upload/Quota Error: $e");
      return null;
    }
  }

  Future<void> triggerGeneration(BuildContext context) async {
    // 1. Initial Storage Checks
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
            content: const Text("Maximum limit of 10 saved exams reached. Delete the oldest exam to proceed?"),
            actions: [
              TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(dialogContext).pop(false)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text("Delete & Continue", style: TextStyle(color: Colors.white)),
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
            String? exactFileName = diag['file_name'] ?? (diag['image_url'] as String?)?.split('/').last.split('?').first;
            if (exactFileName != null) {
              await _assessmentRepo.deleteDiagrams([exactFileName]);
              bytesToFree += (diag['size_bytes'] as int?) ?? (800 * 1024);
            }
          }
        }
        await _assessmentRepo.deleteAssessment(oldestExam['id']);
        if (bytesToFree > 0) {
          await _assessmentRepo.incrementStorage(userId, -bytesToFree);
          if (context.mounted) context.read<AuthViewModel>().adjustStorageLocal(-bytesToFree);
        }
      }
    } catch (e) {
      if (context.mounted) Utils.showSnackBar(context, "Failed to verify history limits.", Colors.redAccent);
      return;
    }

    // 2. Process Diagram Uploads
    List<Map<String, dynamic>> processedDiagramQuestions = [];
    if (wantsDiagrams) {
      for (int i = 0; i < diagramTextControllers.length; i++) {
        String text = diagramTextControllers[i].text.trim();
        File? imageFile = diagramImages[i];

        if (text.isNotEmpty && imageFile == null) {
          Utils.showSnackBar(context, "Please attach an image for Diagram #${i + 1}", Colors.redAccent);
          return;
        }
        if (text.isEmpty && imageFile != null) {
          Utils.showSnackBar(context, "Please write a question for Diagram #${i + 1}", Colors.redAccent);
          return;
        }
        if (text.isNotEmpty && imageFile != null) {
          if (context.mounted) Utils.showSnackBar(context, "Uploading Diagram #${i + 1} to cloud...", Colors.blueAccent);

          try {
            Map<String, dynamic>? uploadData = await _uploadImageToSupabase(imageFile, context);
            if (uploadData != null) {
              processedDiagramQuestions.add({
                "question": text,
                "marks": int.tryParse(diagramMarksControllers[i].text.trim()) ?? 5,
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

    if (_selectedFiles.isEmpty) {
      Utils.showSnackBar(context, "Please upload at least one curriculum file.", Colors.redAccent);
      return;
    }

    _setLoading(true);

    try {
      // 3. Extract Document Text
      String? combinedText = await _documentRepo.extractTextFromFiles(_selectedFiles);
      if (combinedText == null || combinedText.trim().isEmpty) {
        _setLoading(false);
        if (context.mounted) Utils.showSnackBar(context, "Could not extract text. Please check files.", Colors.redAccent);
        return;
      }
      _lastDocumentText = combinedText;

      // 4. Compile the Exact Exam Blueprint
      StringBuffer blueprint = StringBuffer();

      for (int i = 0; i < importedCLOs.length; i++) {
        var clo = importedCLOs[i];
        if (clo['isSelected'] == true) {
          String cloName = "CLO ${i + 1}";
          blueprint.writeln("[$cloName: ${clo['description']}] (BT Level: ${clo['bt_level']})");

          if (wantsMCQs && !randomMCQs) {
            int qty = int.tryParse(clo['mcq_qty'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- MCQs: $qty");
          }
          if (wantsFillBlanks && !randomFillBlanks) {
            int qty = int.tryParse(clo['fib_qty'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- Fill in the Blanks: $qty");
          }
          if (wantsShortQs && !randomShortQs) {
            int qty = int.tryParse(clo['short_qty'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- Short Questions: $qty");
          }
          if (wantsLongQs && !randomLongQs) {
            int qty = int.tryParse(clo['long_qty'].text) ?? 0;
            if (qty > 0) blueprint.writeln("- Long Questions: $qty");
          }
          blueprint.writeln("");
        }
      }

      if ((wantsMCQs && randomMCQs) || (wantsFillBlanks && randomFillBlanks) ||
          (wantsShortQs && randomShortQs) || (wantsLongQs && randomLongQs)) {

        blueprint.writeln("[RANDOMIZED GLOBAL POOL]");
        blueprint.writeln("Distribute the following question quantities randomly across the available CLOs:");
        if (wantsMCQs && randomMCQs) {
          int qty = int.tryParse(globalMcqQtyCtrl.text) ?? 0;
          if (qty > 0) blueprint.writeln("- MCQs: $qty");
        }
        if (wantsFillBlanks && randomFillBlanks) {
          int qty = int.tryParse(globalFibQtyCtrl.text) ?? 0;
          if (qty > 0) blueprint.writeln("- Fill in the Blanks: $qty");
        }
        if (wantsShortQs && randomShortQs) {
          int qty = int.tryParse(globalShortQtyCtrl.text) ?? 0;
          if (qty > 0) blueprint.writeln("- Short Questions: $qty");
        }
        if (wantsLongQs && randomLongQs) {
          int qty = int.tryParse(globalLongQtyCtrl.text) ?? 0;
          if (qty > 0) blueprint.writeln("- Long Questions: $qty");
        }
        blueprint.writeln("");
      }

      // 5. Package Advanced Questions
      List<Map<String, dynamic>> customScenarios = [];
      if (wantsScenariosOrCode) {
        for (var q in advancedQuestions) {
          if (q.textCtrl.text.trim().isNotEmpty) {

            List<Map<String, dynamic>> formattedSubParts = [];
            for (int i = 0; i < q.subParts.length; i++) {
              formattedSubParts.add({
                "label": String.fromCharCode(97 + i),
                "question": q.subParts[i].hintCtrl.text.trim(),
                "marks": int.tryParse(q.subParts[i].marksCtrl.text.trim()) ?? 0,
              });
            }

            customScenarios.add({
              "text": q.textCtrl.text.trim(),
              "marks": q.totalMarks,
              "type": q.type,
              "language": q.langCtrl.text.trim(),
              "target_clo": q.targetClo,
              "sub_parts": formattedSubParts,
            });
          }
        }
      }

      // 6. Execute Gemini Generation
      _generatedAssessment = await _geminiRepo.generateAssessment(
        documentText: combinedText,
        paperCategory: selectedPaperCategory,
        examBlueprint: blueprint.toString(),
        letAIGenerateScenario: letAIGenerateScenario,
        customScenarios: customScenarios,
        diagramQuestions: processedDiagramQuestions,
        allowSubParts: true,
      );

      // 7. Format Metadata
      if (_generatedAssessment != null) {
        _generatedAssessment!['marks'] = {
          "mcq_points": wantsMCQs ? (randomMCQs ? int.tryParse(globalMcqMarksCtrl.text) : int.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['mcq_marks'].text : '1')) ?? 1 : 0,
          "short_points": wantsShortQs ? (randomShortQs ? int.tryParse(globalShortMarksCtrl.text) : int.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['short_marks'].text : '3')) ?? 3 : 0,
          "long_points": wantsLongQs ? (randomLongQs ? int.tryParse(globalLongMarksCtrl.text) : int.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['long_marks'].text : '5')) ?? 5 : 0,
          "fib_points": wantsFillBlanks ? (randomFillBlanks ? int.tryParse(globalFibMarksCtrl.text) : int.tryParse(importedCLOs.isNotEmpty ? importedCLOs[0]['fib_marks'].text : '1')) ?? 1 : 0,
        };
        _generatedAssessment!['diagram_questions'] = processedDiagramQuestions;

        if (_generatedAssessment!['custom_scenarios'] != null) {
          final scenarios = _generatedAssessment!['custom_scenarios'] as List;
          for (int i = 0; i < scenarios.length; i++) {
            if (i < advancedQuestions.length) scenarios[i]['type'] = scenarios[i]['type'] ?? advancedQuestions[i].type;
          }
        }
      }

      _setLoading(false);

      if (_generatedAssessment != null && context.mounted) {
        Utils.showSnackBar(context, "Assessment Generated Successfully!", Colors.green);
      } else {
        if (context.mounted) Utils.showSnackBar(context, "AI failed to generate. Check your API key limit.", Colors.redAccent);
      }
    } catch (e, stacktrace) {
      _setLoading(false);
      debugPrint("Generation Error: $e\n$stacktrace");
      if (context.mounted) Utils.showSnackBar(context, e.toString().replaceAll('Exception:', '').trim(), Colors.redAccent);
    }
  }

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

    wantsMCQs = false; wantsFillBlanks = false; wantsShortQs = false; wantsLongQs = false; wantsScenariosOrCode = false; wantsDiagrams = false;
    randomMCQs = false; randomFillBlanks = false; randomShortQs = false; randomLongQs = false;

    for (var q in advancedQuestions) {
      q.dispose();
    }
    advancedQuestions.clear();
    _addAdvancedQuestionSilent();

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
    await prefs.setString('draft_last_active', DateTime.now().toIso8601String());
    await prefs.setString('draft_category', selectedPaperCategory);
    await prefs.setBool('draft_ai_scenario', letAIGenerateScenario);

    await prefs.setBool('draft_wants_mcq', wantsMCQs);
    await prefs.setBool('draft_wants_fib', wantsFillBlanks);
    await prefs.setBool('draft_wants_short', wantsShortQs);
    await prefs.setBool('draft_wants_long', wantsLongQs);
    await prefs.setBool('draft_wants_scenario', wantsScenariosOrCode);
    await prefs.setBool('draft_wants_diagram', wantsDiagrams);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString('draft_last_active');

    if (lastActiveStr != null) {
      final lastActiveTime = DateTime.parse(lastActiveStr);
      final minutesSinceActive = DateTime.now().difference(lastActiveTime).inMinutes;

      if (minutesSinceActive > _draftExpirationMinutes) {
        await _clearDraftFromMemory(prefs);
        return;
      }
      selectedPaperCategory = prefs.getString('draft_category') ?? 'Theory Based';
      letAIGenerateScenario = prefs.getBool('draft_ai_scenario') ?? true;

      wantsMCQs = prefs.getBool('draft_wants_mcq') ?? false;
      wantsFillBlanks = prefs.getBool('draft_wants_fib') ?? false;
      wantsShortQs = prefs.getBool('draft_wants_short') ?? false;
      wantsLongQs = prefs.getBool('draft_wants_long') ?? false;
      wantsScenariosOrCode = prefs.getBool('draft_wants_scenario') ?? false;
      wantsDiagrams = prefs.getBool('draft_wants_diagram') ?? false;

      notifyListeners();
    }
  }

  Future<void> _clearDraftFromMemory(SharedPreferences prefs) async {
    await prefs.remove('draft_last_active');
    await prefs.remove('draft_category');
    await prefs.remove('draft_ai_scenario');
    await prefs.remove('draft_wants_mcq');
    await prefs.remove('draft_wants_fib');
    await prefs.remove('draft_wants_short');
    await prefs.remove('draft_wants_long');
    await prefs.remove('draft_wants_scenario');
    await prefs.remove('draft_wants_diagram');
  }

  @override
  void dispose() {
    globalMcqQtyCtrl.dispose(); globalMcqMarksCtrl.dispose();
    globalFibQtyCtrl.dispose(); globalFibMarksCtrl.dispose();
    globalShortQtyCtrl.dispose(); globalShortMarksCtrl.dispose();
    globalLongQtyCtrl.dispose(); globalLongMarksCtrl.dispose();
    for (var q in advancedQuestions) q.dispose();
    super.dispose();
  }
}