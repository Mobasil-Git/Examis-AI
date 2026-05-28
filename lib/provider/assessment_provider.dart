import 'package:examis_ai/services/document_service.dart';
import 'package:examis_ai/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';

class AssessmentProvider extends ChangeNotifier {
  final _documentService = DocumentService();
  final _geminiService = GeminiService();
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

  Future<void> fetchDepartments() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select()
          .order('name');

      _departments = List<Map<String, dynamic>>.from(response);
      try {
        _generalDepartment = _departments.firstWhere(
          (dept) => dept['name'].toString().contains('General'),
        );
      } catch (e) {
        debugPrint("General/Shared department not found in list.");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching departments: $e");
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
      return modifiableClo;
    }).toList();
    courseCreditHours = creditHours;

    parseCreditHours(creditHours);
    notifyListeners();
  }

  int get currentConfiguredMarks {
    int total = 0;

    total +=
        (int.tryParse(mcqCountController.text) ?? 0) *
        (int.tryParse(mcqMarksController.text) ?? 0);
    total +=
        (int.tryParse(shortCountController.text) ?? 0) *
        (int.tryParse(shortMarksController.text) ?? 0);
    total +=
        (int.tryParse(longCountController.text) ?? 0) *
        (int.tryParse(longMarksController.text) ?? 0);
    total +=
        (int.tryParse(fillBlankCountController.text) ?? 0) *
        (int.tryParse(fillBlankMarksController.text) ?? 0);

    if (selectedPaperCategory != 'Theory Based') {
      for (var ctrl in scenarioMarksControllers) {
        total += int.tryParse(ctrl.text) ?? 0;
      }
    }

    for (var ctrl in diagramMarksControllers) {
      total += int.tryParse(ctrl.text) ?? 0;
    }

    return total;
  }

  void _onFormChanged() {
    _saveDraft();
    notifyListeners();
  }

  void clearImportedCourse() {
    selectedCourseCode = null;
    selectedCourseTitle = null;
    selectedDepartmentName = null;
    importedCLOs = [];
    notifyListeners();
  }

  void toggleDemoMode(bool value) {
    isDemoMode = value;
    notifyListeners();
  }

  String selectedPaperCategory = 'Theory Based';
  bool letAIGenerateScenario = true;

  // 🚀 NEW: Added tracking for Type and Language
  List<TextEditingController> scenarioTextControllers = [
    TextEditingController(),
  ];
  List<TextEditingController> scenarioMarksControllers = [
    TextEditingController(),
  ];
  List<TextEditingController> scenarioLangControllers = [
    TextEditingController(),
  ];
  List<String> scenarioTypes = ['Scenario'];

  List<TextEditingController> diagramTextControllers = [];
  List<TextEditingController> diagramMarksControllers = [];
  List<File?> diagramImages = [];
  static const int _draftExpirationMinutes = 15;

  AssessmentProvider() {
    _loadDraft();
    _attachSaveListeners();

    if (scenarioMarksControllers.isNotEmpty) {
      scenarioMarksControllers[0].addListener(_onFormChanged);
    }
    if (scenarioLangControllers.isNotEmpty) {
      scenarioLangControllers[0].addListener(_onFormChanged);
    }
    if (diagramMarksControllers.isNotEmpty) {
      diagramMarksControllers[0].addListener(_onFormChanged);
    }
  }

  List<Map<String, dynamic>> _availableBatches = [];
  Map<String, dynamic>? _selectedBatch;

  List<Map<String, dynamic>> get availableBatches => _availableBatches;

  Map<String, dynamic>? get selectedBatch => _selectedBatch;

  List<Map<String, dynamic>> _filteredMasterCourses = [];

  List<Map<String, dynamic>> get filteredMasterCourses =>
      _filteredMasterCourses;

  Future<void> fetchBatches() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('batches')
          .select('id, start_year, end_year, batch_name')
          .order('start_year', ascending: false);

      if (response != null) {
        _availableBatches = List<Map<String, dynamic>>.from(response);

        if (_availableBatches.isNotEmpty) {
          if (_selectedBatch == null) {
            _selectedBatch = _availableBatches.first;
          } else {
            _selectedBatch = _availableBatches.firstWhere(
              (b) => b['id'] == _selectedBatch!['id'],
              orElse: () => _availableBatches.first,
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching batches: $e");
    }
  }

  Future<bool> createNewBatch(int startYear, int endYear) async {
    try {
      final bool alreadyExists = _availableBatches.any(
        (batch) =>
            batch['start_year'] == startYear && batch['end_year'] == endYear,
      );

      if (alreadyExists) {
        debugPrint(
          "Redundancy Blocked: Session $startYear-$endYear already exists.",
        );

        return false;
      }

      final String batchName = "Session $startYear-$endYear";
      final supabase = Supabase.instance.client;
      final newBatch = await supabase
          .from('batches')
          .insert({
            'start_year': startYear,
            'end_year': endYear,
            'batch_name': batchName,
          })
          .select()
          .single();

      _availableBatches.add(newBatch);
      _availableBatches.sort(
        (a, b) => (b['start_year'] as int).compareTo(a['start_year'] as int),
      );

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
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('master_courses')
          .select('id, course_code, title, credit_hours')
          .eq('batch_id', _selectedBatch!['id'])
          .order('title', ascending: true);

      if (response != null) {
        _filteredMasterCourses = List<Map<String, dynamic>>.from(response);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading batch-specific courses: $e");
    }
  }

  void updateSelectedBatch(Map<String, dynamic>? newBatch) {
    if (newBatch != null) {
      _selectedBatch = newBatch;
      notifyListeners();

      fetchCoursesForSelectedBatch();
    }
  }

  String selectedExamType = 'Mid-Term';

  int midTermTarget = 0;
  int finalTermTarget = 0;
  int practicalTarget = 0;
  bool hasPractical = true;

  int vivaWeightage = 0;
  int labTaskWeightage = 0;

  void updateVivaWeightage(String value) {
    int parsedValue = int.tryParse(value) ?? 0;

    if (parsedValue > practicalTarget) {
      parsedValue = practicalTarget;
    }
    if (parsedValue < 0) parsedValue = 0;

    vivaWeightage = parsedValue;
    labTaskWeightage = practicalTarget - vivaWeightage;
    notifyListeners();
  }

  int get currentTargetMarks {
    if (selectedExamType == 'Mid-Term') return midTermTarget;
    if (selectedExamType == 'Final') return finalTermTarget;
    if (selectedExamType == 'Practical') return practicalTarget;
    return 0;
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

  void toggleCloSelection(int index, bool? value) {
    if (value != null) {
      importedCLOs[index]['isSelected'] = value;
      notifyListeners();
    }
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

    await prefs.setString(
      'draft_last_active',
      DateTime.now().toIso8601String(),
    );

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
      final minutesSinceActive = DateTime.now()
          .difference(lastActiveTime)
          .inMinutes;

      if (minutesSinceActive > _draftExpirationMinutes) {
        print("Draft expired ($minutesSinceActive mins). Starting fresh.");
        await _clearDraftFromMemory(prefs);
        return;
      }

      print("Draft restored ($minutesSinceActive mins old).");

      mcqCountController.text = prefs.getString('draft_mcq_count') ?? "";
      mcqMarksController.text = prefs.getString('draft_mcq_marks') ?? "";
      shortCountController.text = prefs.getString('draft_short_count') ?? "";
      shortMarksController.text = prefs.getString('draft_short_marks') ?? "";
      longCountController.text = prefs.getString('draft_long_count') ?? "";
      longMarksController.text = prefs.getString('draft_long_marks') ?? "";
      fillBlankCountController.text = prefs.getString('draft_fib_count') ?? "";
      fillBlankMarksController.text = prefs.getString('draft_fib_marks') ?? "";

      selectedPaperCategory =
          prefs.getString('draft_category') ?? 'Theory Based';
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

  Future<Map<String, dynamic>?> _uploadImageToSupabase(
    File imageFile,
    BuildContext context,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final fileSizeBytes = await imageFile.length();

      final profileResponse = await supabase
          .from('profiles')
          .select('storage_used_bytes, storage_limit_bytes')
          .eq('id', userId)
          .single();

      final int usedBytes = profileResponse['storage_used_bytes'] ?? 0;
      final int limitBytes = profileResponse['storage_limit_bytes'] ?? 52428800;

      if (usedBytes + fileSizeBytes > limitBytes) {
        if (context.mounted) {
          _showError(
            context,
            "Storage Limit Reached! Please upgrade or delete old assessments.",
          );
        }
        return null;
      }

      final fileName = 'diagram_${DateTime.now().millisecondsSinceEpoch}.png';
      await supabase.storage.from('diagrams').upload(fileName, imageFile);

      await supabase.rpc(
        'increment_storage',
        params: {'user_id': userId, 'bytes_to_add': fileSizeBytes},
      );

      if (context.mounted) {
        context.read<AuthProvider>().adjustStorageLocal(fileSizeBytes);
      }

      final url = supabase.storage.from('diagrams').getPublicUrl(fileName);

      return {'url': url, 'file_name': fileName, 'size_bytes': fileSizeBytes};
    } catch (e) {
      print("Supabase Upload/Quota Error: $e");
      return null;
    }
  }

  Future<bool> _checkAndPruneHistory(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final historyResponse = await supabase
          .from('assessments')
          .select('id')
          .eq('user_id', userId);

      if (historyResponse.length >= 10) {
        final oldestExam = await supabase
            .from('assessments')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: true)
            .limit(1)
            .single();

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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text(
                    "Delete Oldest & Continue",
                    style: TextStyle(color: Colors.white),
                  ),
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
            String? exactFileName = diag['file_name'];
            int exactSize = diag['size_bytes'] ?? (800 * 1024);

            if (exactFileName == null && diag['image_url'] != null) {
              String url = diag['image_url'];
              exactFileName = url.split('/').last.split('?').first;
            }

            if (exactFileName != null && exactFileName.isNotEmpty) {
              await supabase.storage.from('diagrams').remove([exactFileName]);
              bytesToFree += exactSize;
              print("Cleaned up orphaned cloud image: $exactFileName");
            }
          }
        }

        await supabase.from('assessments').delete().eq('id', oldestExam['id']);

        if (bytesToFree > 0) {
          await supabase.rpc(
            'increment_storage',
            params: {'user_id': userId, 'bytes_to_add': -bytesToFree},
          );
          if (context.mounted) {
            context.read<AuthProvider>().adjustStorageLocal(-bytesToFree);
          }
        }

        print("Oldest exam deleted successfully.");
      }

      return true;
    } catch (e) {
      print("Error checking history limit: $e");
      if (context.mounted) {
        _showError(context, "Failed to verify history limits.");
      }
      return false;
    }
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
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        diagramImages[index] = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      print("Error picking diagram: $e");
    }
  }

  Future<Map<String, dynamic>?> extractCourseWithGemini(XFile imageFile) async {
    final result = await _geminiService.extractCourseSyllabusFromImage(
      File(imageFile.path),
    );
    return result;
  }

  void toggleAIGenerateScenario(bool? value) {
    if (value != null) {
      letAIGenerateScenario = value;
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

  // 🚀 NEW: Update Scenario Type
  void updateScenarioType(int index, String newType) {
    scenarioTypes[index] = newType;
    _onFormChanged();
  }

  void updatePaperCategory(String? newValue) {
    if (newValue != null) {
      selectedPaperCategory = newValue;
      _onFormChanged();
    }
  }

  String _lastPaperCategory = 'Theory Based';

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

  final TextEditingController mcqCountController = TextEditingController();
  final TextEditingController mcqMarksController = TextEditingController();
  final TextEditingController shortCountController = TextEditingController();
  final TextEditingController shortMarksController = TextEditingController();
  final TextEditingController longCountController = TextEditingController();
  final TextEditingController longMarksController = TextEditingController();
  final fillBlankCountController = TextEditingController();
  final fillBlankMarksController = TextEditingController();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> pickFile(BuildContext context) async {
    if (!canAddMoreFiles) {
      _showError(
        context,
        "You can only upload up to $maxFiles files at a time.",
      );
      return;
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx'],
        allowMultiple: true,
      );

      if (result != null) {
        for (var file in result.files) {
          if (_selectedFiles.any((existing) => existing.name == file.name)) {
            _showError(context, "${file.name} is already added.");
            continue;
          }
          if (file.size > maxFileSizeInBytes) {
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

  Future<void> triggerGeneration(BuildContext context) async {
    bool canProceed = await _checkAndPruneHistory(context);
    if (!canProceed) {
      return;
    }
    List<Map<String, dynamic>> diagramQuestions = [];

    for (int i = 0; i < diagramTextControllers.length; i++) {
      String text = diagramTextControllers[i].text.trim();
      String marksText = diagramMarksControllers[i].text.trim();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Uploading Diagram #${i + 1} to cloud...")),
          );
        }

        Map<String, dynamic>? uploadData = await _uploadImageToSupabase(
          imageFile,
          context,
        );

        if (uploadData != null) {
          diagramQuestions.add({
            "question": text,
            "marks": int.tryParse(marksText) ?? 5,
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
    final fillBlankCount =
        int.tryParse(fillBlankCountController.text.trim()) ?? 0;

    if (mcqCount == 0 &&
        shortCount == 0 &&
        longCount == 0 &&
        fillBlankCount == 0 &&
        diagramQuestions.isEmpty) {
      _showError(context, "Please request at least one type of question.");
      return;
    }

    _setLoading(true);

    if (isDemoMode) {
      print("DEMO MODE ACTIVE: Bypassing Gemini API...");
      await Future.delayed(const Duration(seconds: 2));
      _setLoading(false);
      return;
    }

    try {
      for (var file in _selectedFiles) {
        if (file.path == null || !File(file.path!).existsSync()) {
          _setLoading(false);
          if (context.mounted) {
            _showError(
              context,
              "The file '${file.name}' was cleared from the device cache. Please remove and re-select it.",
            );
          }
          return;
        }
      }
      String? combinedText = await _documentService.extractTextFromFiles(
        _selectedFiles,
      );

      if (combinedText == null || combinedText.trim().isEmpty) {
        _setLoading(false);
        if (context.mounted) {
          _showError(
            context,
            "Could not extract text. Please check your files or server connection.",
          );
        }
        return;
      }

      String getFullDomainName(String domainChar) {
        switch (domainChar.toUpperCase()) {
          case 'P':
            return 'Psychomotor (Manual/Coding Skills)';
          case 'A':
            return 'Affective (Ethics/Attitude)';
          case 'C':
          default:
            return 'Cognitive (Mental/Theory Skills)';
        }
      }

      List<String> activeCLOs = [];
      for (int i = 0; i < importedCLOs.length; i++) {
        final clo = importedCLOs[i];
        if (clo['isSelected'] == true) {
          String domainFull = getFullDomainName(
            clo['domain']?.toString() ?? 'C',
          );
          activeCLOs.add(
            "CLO ${i + 1}: [Domain: $domainFull] [BT Level: ${clo['bt_level']}] ${clo['description'].toString().trim()}",
          );
        }
      }

      _lastDocumentText = combinedText;
      _lastPaperCategory = selectedPaperCategory;

      List<Map<String, dynamic>> customScenarios = [];

      // 🚀 THE FIX: Package language and type data!
      for (int i = 0; i < scenarioTextControllers.length; i++) {
        String text = scenarioTextControllers[i].text.trim();
        String marksText = scenarioMarksControllers[i].text.trim();
        String type = scenarioTypes[i];
        String lang = scenarioLangControllers[i].text.trim();

        if (text.isNotEmpty) {
          customScenarios.add({
            "text": text,
            "marks": int.tryParse(marksText) ?? 0,
            "type": type,
            "language": lang,
          });
        }
      }

      _generatedAssessment = await _geminiService.generateAssessment(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assessment Generated Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (context.mounted) {
          _showError(context, "AI failed to generate. Please try again.");
        }
      }
    } catch (e) {
      _setLoading(false);
      if (context.mounted) _showError(context, "An unexpected error occurred.");
    }
  }

  Future<void> regenerateSingleItem(
    BuildContext context,
    String type,
    int index,
  ) async {
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

      final newQuestion = await _geminiService.regenerateSingleQuestion(
        documentText: _lastDocumentText,
        questionType: type,
        paperCategory: _lastPaperCategory,
        targetClo: existingClo,
      );

      if (newQuestion != null && _generatedAssessment != null) {
        if (existingClo != null) {
          newQuestion['target_clo'] = existingClo;
        }
        _generatedAssessment![type][index] = newQuestion;
      } else {
        if (context.mounted)
          _showError(context, "Failed to regenerate question.");
      }
    } catch (e) {
      if (context.mounted)
        _showError(context, "An error occurred during regeneration.");
    }

    _regeneratingItems.remove(itemKey);
    notifyListeners();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
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

  @override
  void dispose() {
    mcqCountController.dispose();
    mcqMarksController.dispose();
    shortCountController.dispose();
    shortMarksController.dispose();
    longCountController.dispose();
    longMarksController.dispose();
    for (var ctrl in scenarioTextControllers) {
      ctrl.dispose();
    }
    for (var ctrl in scenarioMarksControllers) {
      ctrl.dispose();
    }
    for (var ctrl in scenarioLangControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }
}
