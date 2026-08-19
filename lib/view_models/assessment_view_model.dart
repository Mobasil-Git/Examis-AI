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

  List<TextEditingController> scenarioTextControllers = [TextEditingController()];
  List<TextEditingController> scenarioMarksControllers = [TextEditingController()];
  List<TextEditingController> scenarioLangControllers = [TextEditingController()];
  List<String> scenarioTypes = ['Scenario'];

  List<TextEditingController> diagramTextControllers = [];
  List<TextEditingController> diagramMarksControllers = [];
  List<File?> diagramImages = [];
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

  final TextEditingController mcqCountController = TextEditingController();
  final TextEditingController mcqMarksController = TextEditingController();
  final TextEditingController shortCountController = TextEditingController();
  final TextEditingController shortMarksController = TextEditingController();
  final TextEditingController longCountController = TextEditingController();
  final TextEditingController longMarksController = TextEditingController();
  final fillBlankCountController = TextEditingController();
  final fillBlankMarksController = TextEditingController();

  AssessmentViewModel() {
    _loadDraft();
    _attachSaveListeners();

    if (scenarioMarksControllers.isNotEmpty) scenarioMarksControllers[0].addListener(_onFormChanged);
    if (scenarioLangControllers.isNotEmpty) scenarioLangControllers[0].addListener(_onFormChanged);
    if (diagramMarksControllers.isNotEmpty) diagramMarksControllers[0].addListener(_onFormChanged);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _onFormChanged() {
    _saveDraft();
    notifyListeners();
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
      if (_availableBatches.isNotEmpty) {
        _selectedBatch ??= _availableBatches.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching batches: $e");
    }
  }

  Future<bool> createNewBatch(int startYear, int endYear) async {
    try {
      final bool alreadyExists = _availableBatches.any(
            (batch) => batch['start_year'] == startYear && batch['end_year'] == endYear,
      );
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
      return modifiableClo;
    }).toList();
    courseCreditHours = creditHours;
    parseCreditHours(creditHours);
    notifyListeners();
  }

  void clearImportedCourse() {
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
    total += (int.tryParse(mcqCountController.text) ?? 0) * (int.tryParse(mcqMarksController.text) ?? 0);
    total += (int.tryParse(shortCountController.text) ?? 0) * (int.tryParse(shortMarksController.text) ?? 0);
    total += (int.tryParse(longCountController.text) ?? 0) * (int.tryParse(longMarksController.text) ?? 0);
    total += (int.tryParse(fillBlankCountController.text) ?? 0) * (int.tryParse(fillBlankMarksController.text) ?? 0);

    if (selectedPaperCategory != 'Theory Based') {
      for (var ctrl in scenarioMarksControllers) total += int.tryParse(ctrl.text) ?? 0;
    }
    for (var ctrl in diagramMarksControllers) total += int.tryParse(ctrl.text) ?? 0;
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

  void addCustomScenario() {
    final textCtrl = TextEditingController();
    final marksCtrl = TextEditingController();
    final langCtrl = TextEditingController();
    marksCtrl.addListener(_onFormChanged);
    langCtrl.addListener(_onFormChanged);

    scenarioTextControllers.add(textCtrl);
    scenarioMarksControllers.add(marksCtrl);
    scenarioLangControllers.add(langCtrl);
    scenarioTypes.add('Scenario');
    _onFormChanged();
  }

  void removeCustomScenario(int index) {
    if (scenarioTextControllers.length > 1) {
      scenarioTextControllers[index].dispose();
      scenarioMarksControllers[index].dispose();
      scenarioLangControllers[index].dispose();
      scenarioTextControllers.removeAt(index);
      scenarioMarksControllers.removeAt(index);
      scenarioLangControllers.removeAt(index);
      scenarioTypes.removeAt(index);
      _onFormChanged();
    }
  }

  void updateScenarioType(int index, String newType) {
    scenarioTypes[index] = newType;
    _onFormChanged();
  }

  void addDiagramQuestion() {
    final textCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: "5");
    marksCtrl.addListener(_onFormChanged);

    diagramTextControllers.add(textCtrl);
    diagramMarksControllers.add(marksCtrl);
    diagramImages.add(null);
    _onFormChanged();
  }

  void removeDiagramQuestion(int index) {
    diagramTextControllers[index].dispose();
    diagramMarksControllers[index].dispose();
    diagramTextControllers.removeAt(index);
    diagramMarksControllers.removeAt(index);
    diagramImages.removeAt(index);
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
      _showError(context, "You can only upload up to $maxFiles files at a time.");
      return;
    }
    try {
      // Pick files and securely handle the List<PlatformFile> without assuming properties
      List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx'],
      ) ?? [];

      if (files.isNotEmpty) {
        for (var file in files) {
          if (_selectedFiles.any((existing) => existing.name == file.name)) {
            _showError(context, "${file.name} is already added.");
            continue;
          }

          // Securely check limits natively on the device
          final int fileSize = file.path != null ? File(file.path!).lengthSync() : 0;
          if (fileSize > maxFileSizeInBytes) {
            _showError(context, "${file.name} exceeds the 10MB limit.");
            continue;
          }
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

  Future<bool> _checkAndPruneHistory(BuildContext context) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final historyResponse = await _assessmentRepo.fetchUserAssessments(userId);

      if (historyResponse.length >= 10) {
        final oldestExam = historyResponse.first;

        if (!context.mounted) return false;
        bool? shouldDelete = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text("History Limit Reached"),
              content: const Text(
                "You have reached the maximum limit of 10 saved exams. "
                    "To generate a new one, your oldest exam will be permanently deleted. "
                    "Do you want to proceed?",
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text("Delete Oldest & Continue", style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        );

        if (shouldDelete != true) return false;

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
          if (context.mounted) {
            context.read<AuthViewModel>().adjustStorageLocal(-bytesToFree);
          }
        }
      }
      return true;
    } catch (e) {
      if (context.mounted) _showError(context, "Failed to verify history limits.");
      return false;
    }
  }

  Future<Map<String, dynamic>?> _uploadImageToSupabase(File imageFile, BuildContext context) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileSizeBytes = await imageFile.length();
      final profileResponse = await _assessmentRepo.fetchProfileStorage(userId);

      final int usedBytes = profileResponse['storage_used_bytes'] ?? 0;
      final int limitBytes = profileResponse['storage_limit_bytes'] ?? 52428800;

      if (usedBytes + fileSizeBytes > limitBytes) {
        if (context.mounted) _showError(context, "Storage Limit Reached! Please upgrade or delete old assessments.");
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
    bool canProceed = await _checkAndPruneHistory(context);
    if (!canProceed) return;

    List<Map<String, dynamic>> diagramQuestions = [];
    for (int i = 0; i < diagramTextControllers.length; i++) {
      String text = diagramTextControllers[i].text.trim();
      File? imageFile = diagramImages[i];

      if (text.isNotEmpty && imageFile == null) {
        _showError(context, "Please attach an image for Diagram #${i + 1}");
        return;
      }
      if (text.isEmpty && imageFile != null) {
        _showError(context, "Please write a question for Diagram #${i + 1}");
        return;
      }
      if (text.isNotEmpty && imageFile != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Uploading Diagram #${i + 1} to cloud...")));
        }
        Map<String, dynamic>? uploadData = await _uploadImageToSupabase(imageFile, context);
        if (uploadData != null) {
          diagramQuestions.add({
            "question": text,
            "marks": int.tryParse(diagramMarksControllers[i].text.trim()) ?? 5,
            "image_url": uploadData['url'],
            "file_name": uploadData['file_name'],
            "size_bytes": uploadData['size_bytes'],
            "target_clo": "CLO 1",
          });
        } else {
          _showError(context, "Upload Failed.");
          return;
        }
      }
    }

    _generatedAssessment = null;
    if (_selectedFiles.isEmpty) {
      _showError(context, "Please upload at least one curriculum file.");
      return;
    }

    final mcqCount = int.tryParse(mcqCountController.text.trim()) ?? 0;
    final shortCount = int.tryParse(shortCountController.text.trim()) ?? 0;
    final longCount = int.tryParse(longCountController.text.trim()) ?? 0;
    final fillBlankCount = int.tryParse(fillBlankCountController.text.trim()) ?? 0;

    if (mcqCount == 0 && shortCount == 0 && longCount == 0 && fillBlankCount == 0 && diagramQuestions.isEmpty) {
      _showError(context, "Please request at least one type of question.");
      return;
    }

    _setLoading(true);
    if (isDemoMode) {
      await Future.delayed(const Duration(seconds: 2));
      _setLoading(false);
      return;
    }

    try {
      String? combinedText = await _documentRepo.extractTextFromFiles(_selectedFiles);
      if (combinedText == null || combinedText.trim().isEmpty) {
        _setLoading(false);
        if (context.mounted) _showError(context, "Could not extract text. Please check files/connection.");
        return;
      }

      List<String> activeCLOs = [];
      for (int i = 0; i < importedCLOs.length; i++) {
        if (importedCLOs[i]['isSelected'] == true) {
          String domain = importedCLOs[i]['domain']?.toString() ?? 'C';
          String domainFull = domain == 'P' ? 'Psychomotor' : domain == 'A' ? 'Affective' : 'Cognitive';
          activeCLOs.add("CLO ${i + 1}: [Domain: $domainFull] [BT Level: ${importedCLOs[i]['bt_level']}] ${importedCLOs[i]['description']}");
        }
      }

      _lastDocumentText = combinedText;
      List<Map<String, dynamic>> customScenarios = [];
      for (int i = 0; i < scenarioTextControllers.length; i++) {
        if (scenarioTextControllers[i].text.trim().isNotEmpty) {
          customScenarios.add({
            "text": scenarioTextControllers[i].text.trim(),
            "marks": int.tryParse(scenarioMarksControllers[i].text.trim()) ?? 0,
            "type": scenarioTypes[i],
            "language": scenarioLangControllers[i].text.trim(),
          });
        }
      }

      _generatedAssessment = await _geminiRepo.generateAssessment(
        documentText: combinedText,
        paperCategory: selectedPaperCategory,
        mcqCount: mcqCount,
        shortQCount: shortCount,
        longQCount: longCount,
        fillBlankCount: fillBlankCount,
        activeCLOs: activeCLOs,
        letAIGenerateScenario: letAIGenerateScenario,
        customScenarios: customScenarios,
        diagramQuestions: diagramQuestions,
      );

      if (_generatedAssessment != null) {
        _generatedAssessment!['marks'] = {
          "mcq_points": int.tryParse(mcqMarksController.text.trim()) ?? 1,
          "short_points": int.tryParse(shortMarksController.text.trim()) ?? 3,
          "long_points": int.tryParse(longMarksController.text.trim()) ?? 5,
          "fib_points": int.tryParse(fillBlankMarksController.text.trim()) ?? 1,
        };
        _generatedAssessment!['diagram_questions'] = diagramQuestions;
      }
      _setLoading(false);

      if (_generatedAssessment != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assessment Generated Successfully!"), backgroundColor: Colors.green));
      } else {
        if (context.mounted) _showError(context, "AI failed to generate.");
      }
    } catch (e) {
      _setLoading(false);
      if (context.mounted) _showError(context, "An unexpected error occurred.");
    }
  }

  Future<void> regenerateSingleItem(BuildContext context, String type, int index) async {
    if (_lastDocumentText.isEmpty) {
      _showError(context, "Context lost. Please generate a new assessment.");
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
        if (context.mounted) _showError(context, "Failed to regenerate question.");
      }
    } catch (e) {
      if (context.mounted) _showError(context, e.toString());
    }

    _regeneratingItems.remove(itemKey);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> extractCourseWithGemini(XFile imageFile) async {
    return await _geminiRepo.extractCourseSyllabusFromImage(File(imageFile.path));
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
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

    mcqCountController.clear();
    mcqMarksController.clear();
    shortCountController.clear();
    shortMarksController.clear();
    longCountController.clear();
    longMarksController.clear();

    clearImportedCourse();
    final prefs = await SharedPreferences.getInstance();
    await _clearDraftFromMemory(prefs);
    notifyListeners();
  }

  void _attachSaveListeners() {
    mcqCountController.addListener(_onFormChanged);
    mcqMarksController.addListener(_onFormChanged);
    shortCountController.addListener(_onFormChanged);
    shortMarksController.addListener(_onFormChanged);
    longCountController.addListener(_onFormChanged);
    longMarksController.addListener(_onFormChanged);
    fillBlankCountController.addListener(_onFormChanged);
    fillBlankMarksController.addListener(_onFormChanged);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_last_active', DateTime.now().toIso8601String());
    await prefs.setString('draft_mcq_count', mcqCountController.text);
    await prefs.setString('draft_mcq_marks', mcqMarksController.text);
    await prefs.setString('draft_short_count', shortCountController.text);
    await prefs.setString('draft_short_marks', shortMarksController.text);
    await prefs.setString('draft_long_count', longCountController.text);
    await prefs.setString('draft_long_marks', longMarksController.text);
    await prefs.setString('draft_fib_count', fillBlankCountController.text);
    await prefs.setString('draft_fib_marks', fillBlankMarksController.text);
    await prefs.setString('draft_category', selectedPaperCategory);
    await prefs.setBool('draft_ai_scenario', letAIGenerateScenario);
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

      mcqCountController.text = prefs.getString('draft_mcq_count') ?? "";
      mcqMarksController.text = prefs.getString('draft_mcq_marks') ?? "";
      shortCountController.text = prefs.getString('draft_short_count') ?? "";
      shortMarksController.text = prefs.getString('draft_short_marks') ?? "";
      longCountController.text = prefs.getString('draft_long_count') ?? "";
      longMarksController.text = prefs.getString('draft_long_marks') ?? "";
      fillBlankCountController.text = prefs.getString('draft_fib_count') ?? "";
      fillBlankMarksController.text = prefs.getString('draft_fib_marks') ?? "";

      selectedPaperCategory = prefs.getString('draft_category') ?? 'Theory Based';
      letAIGenerateScenario = prefs.getBool('draft_ai_scenario') ?? true;
      notifyListeners();
    }
  }

  Future<void> _clearDraftFromMemory(SharedPreferences prefs) async {
    await prefs.remove('draft_last_active');
    await prefs.remove('draft_mcq_count');
    await prefs.remove('draft_mcq_marks');
    await prefs.remove('draft_short_count');
    await prefs.remove('draft_short_marks');
    await prefs.remove('draft_long_count');
    await prefs.remove('draft_long_marks');
    await prefs.remove('draft_fib_count');
    await prefs.remove('draft_fib_marks');
    await prefs.remove('draft_category');
    await prefs.remove('draft_ai_scenario');
  }

  @override
  void dispose() {
    mcqCountController.dispose();
    mcqMarksController.dispose();
    shortCountController.dispose();
    shortMarksController.dispose();
    longCountController.dispose();
    longMarksController.dispose();
    for (var ctrl in scenarioTextControllers) ctrl.dispose();
    for (var ctrl in scenarioMarksControllers) ctrl.dispose();
    for (var ctrl in scenarioLangControllers) ctrl.dispose();
    super.dispose();
  }
}