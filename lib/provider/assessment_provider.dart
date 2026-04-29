import 'package:examis_ai/services/document_service.dart';
import 'package:examis_ai/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AssessmentProvider extends ChangeNotifier {
  final _documentService = DocumentService();
  final _geminiService = GeminiService();

  // --- NEW: Paper Category State ---
  String selectedPaperCategory = 'Theory Based';
  // --- UPGRADED: Custom Scenario State ---
  bool letAIGenerateScenario = true;

  // Lists to hold multiple scenarios and their specific marks
  List<TextEditingController> scenarioTextControllers = [TextEditingController()];
  List<TextEditingController> scenarioMarksControllers = [TextEditingController()];

  // --- NEW: Camera/CLO Extraction State ---
  bool isExtractingCLOs = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> scanCLOsFromImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80); // 80 quality saves API upload time

      if (image == null) return; // User canceled the picker

      isExtractingCLOs = true;
      notifyListeners();

      final extractedCLOs = await _geminiService.extractCLOsFromImage(File(image.path));

      if (extractedCLOs.isNotEmpty) {
        // Clear existing empty boxes
        if (cloControllers.length == 1 && cloControllers[0].text.isEmpty) {
          cloControllers.clear();
        }

        // Add all the newly extracted CLOs!
        for (String clo in extractedCLOs) {
          cloControllers.add(TextEditingController(text: clo));
        }
      }

    } catch (e) {
      print("Error scanning CLOs: $e");
    } finally {
      isExtractingCLOs = false;
      notifyListeners();
    }
  }

  void toggleAIGenerateScenario(bool? value) {
    if (value != null) {
      letAIGenerateScenario = value;
      notifyListeners();
    }
  }

  void addCustomScenario() {
    scenarioTextControllers.add(TextEditingController());
    scenarioMarksControllers.add(TextEditingController());
    notifyListeners();
  }

  void removeCustomScenario(int index) {
    if (scenarioTextControllers.length > 1) {
      scenarioTextControllers[index].dispose();
      scenarioMarksControllers[index].dispose();
      scenarioTextControllers.removeAt(index);
      scenarioMarksControllers.removeAt(index);
      notifyListeners();
    }
  }
  void updatePaperCategory(String? newValue) {
    if (newValue != null) {
      selectedPaperCategory = newValue;
      notifyListeners();
    }
  }

  String _lastPaperCategory = 'Theory Based'; // For regeneration memory!

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
  String _lastDifficulty = "Standard";
  final Set<String> _regeneratingItems = {};

  bool isRegenerating(String type, int index) =>
      _regeneratingItems.contains("${type}_$index");

  final TextEditingController variationsController = TextEditingController();
  final TextEditingController mcqCountController = TextEditingController();
  final TextEditingController mcqMarksController = TextEditingController();
  final TextEditingController shortCountController = TextEditingController();
  final TextEditingController shortMarksController = TextEditingController();
  final TextEditingController longCountController = TextEditingController();
  final TextEditingController longMarksController = TextEditingController();
  final fillBlankCountController = TextEditingController();
  final fillBlankMarksController = TextEditingController();
  List<TextEditingController> cloControllers = [TextEditingController()];

  void addClo() {
    cloControllers.add(TextEditingController());
    notifyListeners();
  }

  void removeClo(int index) {
    if (cloControllers.length > 1) {
      cloControllers[index].dispose();
      cloControllers.removeAt(index);
      notifyListeners();
    }
  }

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
        allowedExtensions: ['pdf'],
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

  Future<void> triggerGeneration(
      BuildContext context, {
        required String difficulty,
      }) async {

    // ==========================================
    // 👇 ADD THIS LINE TO KILL THE GHOST STATE 👇
    // ==========================================
    _generatedAssessment = null;

    if (_selectedFiles.isEmpty) {
      _showError(context, "Please upload at least one curriculum file.");
      return;
    }

    final mcqCount = int.tryParse(mcqCountController.text.trim()) ?? 0;
    final shortCount = int.tryParse(shortCountController.text.trim()) ?? 0;
    final longCount = int.tryParse(longCountController.text.trim()) ?? 0;
    final fillBlankCount = int.tryParse(fillBlankCountController.text.trim()) ?? 0;

    if (mcqCount == 0 &&
        shortCount == 0 &&
        longCount == 0 &&
        fillBlankCount == 0) {
      _showError(context, "Please request at least one type of question.");
      return;
    }

    _setLoading(true);

    try {
      String combinedText = "";
      for (var file in _selectedFiles) {
        if (file.path != null) {
          final text = await _documentService.extractTextFromPDF(file.path!);
          if (text != null) combinedText += "$text\n\n";
        }
      }

      if (combinedText.trim().isEmpty) {
        _setLoading(false);
        if (context.mounted)
          _showError(
            context,
            "Could not extract text. PDFs might be image-based.",
          );
        return;
      }

      List<String> activeCLOs = cloControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      // SAVE TO MEMORY SO WE CAN USE IT FOR REGENERATION LATER
      _lastDocumentText = combinedText;
      _lastDifficulty = difficulty;
      _lastPaperCategory = selectedPaperCategory;

      // NEW: Extract custom scenarios and their marks into a list of maps
      List<Map<String, dynamic>> customScenarios = [];

      for (int i = 0; i < scenarioTextControllers.length; i++) {
        String text = scenarioTextControllers[i].text.trim();
        String marksText = scenarioMarksControllers[i].text.trim();

        if (text.isNotEmpty) {
          customScenarios.add({
            "text": text,
            "marks": int.tryParse(marksText) ?? 0 // <--- Safely parsed to an Integer!
          });
        }
      }

      _generatedAssessment = await _geminiService.generateAssessment(
        documentText: combinedText,
        difficulty: difficulty,
        paperCategory: selectedPaperCategory,
        mcqCount: mcqCount,
        shortQCount: shortCount,
        longQCount: longCount,
        fillBlankCount: fillBlankCount,
        activeCLOs: activeCLOs,
        letAIGenerateScenario: letAIGenerateScenario,
        customScenarios: customScenarios, // <--- Passed the new list!
      );

      if (_generatedAssessment != null) {
        // 1. Inject the marks
        _generatedAssessment!['marks'] = {
          "mcq_points": int.tryParse(mcqMarksController.text.trim()) ?? 1,
          "short_points": int.tryParse(shortMarksController.text.trim()) ?? 3,
          "long_points": int.tryParse(longMarksController.text.trim()) ?? 5,
          "fib_points": int.tryParse(fillBlankMarksController.text.trim()) ?? 1,
        };

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
        if (context.mounted)
          _showError(context, "AI failed to generate. Please try again.");
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
        difficulty: _lastDifficulty,
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

  void clearData() {
    _selectedFiles.clear();
    _generatedAssessment = null;
    _isLoading = false;
    _lastDocumentText = "";
    _regeneratingItems.clear();

    variationsController.clear();
    mcqCountController.clear();
    mcqMarksController.clear();
    shortCountController.clear();
    shortMarksController.clear();
    longCountController.clear();
    longMarksController.clear();
    cloControllers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    variationsController.dispose();
    mcqCountController.dispose();
    mcqMarksController.dispose();
    shortCountController.dispose();
    shortMarksController.dispose();
    longCountController.dispose();
    longMarksController.dispose();
    super.dispose();
  }
}
