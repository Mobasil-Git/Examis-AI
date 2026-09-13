import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import '../data/local/shared_pref_manager.dart';

class GeminiRepository {

  Future<GenerativeModel> _getDynamicModel({bool isExtraction = false}) async {
    final prefs = SharedPrefManager();
    final tier = await prefs.getUserTier();
    final customKey = await prefs.getCustomApiKey();

    String activeKey = isExtraction
        ? (dotenv.env['DOCUMENT_EXTRACTION_API_KEY'] ?? '')
        : (dotenv.env['GEMINI_API_KEY'] ?? '');

    if (tier == 'free' && customKey != null && customKey.isNotEmpty) {
      activeKey = customKey;
    }

    // UPDATED: Leveraging Gemini 3.6 Flash for superior mult-step orchestration and structured output.
    return GenerativeModel(
      model: 'gemini-3.6-flash',
      apiKey: activeKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
      ),
    );
  }

  String _getMasterBloomTaxonomyRules() {
    return """
    UNIVERSAL EDUCATIONAL STANDARDS (STRICT ENFORCEMENT):
    You must match the cognitive difficulty and the educational domain of EVERY single generated question to the exact 'Domain' and 'BT Level' specified in its assigned CLO.

    --- DOMAIN RULES ---
    1. Cognitive Domain: The question must test mental skills, theory, recall, and logical analysis.
    2. Psychomotor Domain: The question MUST require the student to actively "do" something physical.
    3. Affective Domain: The question must test the student's attitude, professional ethics, or understanding of societal impact.
    """;
  }

  Future<Map<String, dynamic>?> generateAssessment({
    required String documentText,
    required String paperCategory,
    required String examBlueprint,
    bool letAIGenerateScenario = true,
    List<Map<String, dynamic>> customScenarios = const [],
    List<Map<String, dynamic>> diagramQuestions = const [],
    bool allowSubParts = false,
  }) async {
    String bloomInstruction = _getMasterBloomTaxonomyRules();

    String subPartField = "";
    String subPartInstruction = "";
    if (allowSubParts) {
      subPartField = '''
      ,
      "sub_parts": [
        {
          "label": "a",
          "question": "A logical sub-question",
          "marks": 5
        }
      ]
      ''';
      subPartInstruction = """
      SUB-PART RULE: 
      If a Long Question, Short Question, or Custom Scenario requires detailed analysis, you MUST break the question down into logical "sub_parts" (e.g., a, b). 
      Split the total marks for that question logically across the sub-parts.
      """;
    }

    String categoryInstruction = "";
    if (paperCategory == "Theory Based") {
      categoryInstruction = "CRITICAL PAPER STYLE: Focus strictly on definitions, principles, and theoretical concepts. Do NOT invent scenarios.";
    } else if (paperCategory == "Theory + Code/Scenario") {
      categoryInstruction = "CRITICAL PAPER STYLE: Generate a balanced mix. Half the questions should test theoretical recall, and the other half MUST present a short real-world scenario or a block of code to analyze.";
    } else if (paperCategory == "Strictly Code/Scenario") {
      categoryInstruction = "CRITICAL PAPER STYLE: Every single question MUST present a real-world scenario, a case study, or a block of code to analyze. Do NOT ask for simple definitions or direct theoretical recall.";
    }

    String scenarioInstruction = "";
    String scenarioJsonField = "";

    if (paperCategory != "Theory Based" && customScenarios.isNotEmpty) {
      String formattedRequests = customScenarios.asMap().entries.map((e) {
        final sc = e.value;
        String cloTarget = sc['target_clo'] != null ? " (Target: ${sc['target_clo']})" : "";
        if (sc['type'] == 'Code') {
          return "Item ${e.key + 1} (Marks: ${sc['marks']})$cloTarget: STRICT CODE GENERATION. Language: ${sc['language']}. Topic: ${sc['text']}.";
        } else {
          return "Item ${e.key + 1} (Marks: ${sc['marks']})$cloTarget: STRICT SCENARIO GENERATION. Topic: ${sc['text']}.";
        }
      }).join("\n\n");

      if (letAIGenerateScenario) {
        scenarioInstruction = """
        SCENARIO & CODE RULES: Generate ${customScenarios.length} items based EXACTLY on the following instructions.
        For each generated item, include a "type" attribute set to exactly "Scenario" or "Code".
        [TEACHER INSTRUCTIONS]
        $formattedRequests
        """;
      } else {
        scenarioInstruction = "SCENARIO RULE: You MUST use the EXACT text provided below for the scenarios.\n[EXACT TEXT]\n$formattedRequests";
      }

      scenarioJsonField = '''
        ,
        "custom_scenarios": [
          {
            "text": "The full scenario text or code block...",
            "marks": 10,
            "type": "Scenario",
            "target_clo": "CLO 1"$subPartField
          }
        ]
      ''';
    }

    String diagramInstruction = "";
    String diagramJsonField = "";

    if (diagramQuestions.isNotEmpty) {
      String formattedDiagrams = diagramQuestions.asMap().entries.map(
            (e) => "Diagram Question ${e.key + 1} (Marks: ${e.value['marks']}, URL: ${e.value['image_url']}, Target: ${e.value['target_clo'] ?? 'Any'}): ${e.value['question']}",
      ).join("\n");

      diagramInstruction = """
      DIAGRAM QUESTIONS RULE: The teacher has provided pre-written diagram-based questions.
      You MUST strictly pass these EXACT questions through to the final JSON under the "diagram_questions" array.
      [TEACHER DIAGRAMS]
      $formattedDiagrams
      """;

      diagramJsonField = '''
        ,
        "diagram_questions": [
          {
            "question": "The exact question text provided",
            "image_url": "The exact image_url provided",
            "marks": 5,
            "target_clo": "CLO X"
          }
        ]
      ''';
    }

    final prompt = '''
      You are an expert educational assessment generator.
      Analyze the following document text and generate an exam based STRICTLY on the Exact Exam Blueprint provided below.
      
      $bloomInstruction
      $categoryInstruction
      $scenarioInstruction
      $diagramInstruction
      $subPartInstruction

      CRITICAL BLUEPRINT ENFORCEMENT:
      You are strictly required to generate the exact number of questions per CLO as defined in this blueprint. Do not invent questions. Do not skip questions. Map the "target_clo" field in the JSON exactly as requested.

      --- EXACT EXAM BLUEPRINT ---
      $examBlueprint
      ----------------------------

      You must return the data strictly in the following JSON structure:
      {
        "title": "A short, relevant title for this assessment"$scenarioJsonField,
        "mcqs": [
          {
            "question": "The question text here?",
            "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
            "correctAnswer": "Exact text of the correct option",
            "target_clo": "CLO X"
          }
        ],
        "fillInTheBlanks": [
          {
            "question": "The capital of France is ________.",
            "answer": "Paris",
            "target_clo": "CLO X"
          }
        ],
        "shortQuestions": [
          {
            "question": "The short answer question text?",
            "idealAnswer": "A brief ideal answer",
            "target_clo": "CLO X"$subPartField
          }
        ],
        "longQuestions": [
          {
            "question": "The long essay question text?",
            "gradingRubric": "Rubric guide",
            "target_clo": "CLO X"$subPartField
          }
        ]$diagramJsonField
      }

      Document Text:
      """
      $documentText
      """
    ''';

    final model = await _getDynamicModel(isExtraction: false);
    int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null || text.isEmpty) return null;
        return jsonDecode(text.replaceAll('```json', '').replaceAll('```', '').trim());
      } catch (e) {
        if (e.toString().contains('503') || e.toString().contains('429')) {
          if (attempt == maxRetries) throw Exception("Gemini Rate Limit Hit. Please try again later.");
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          throw Exception("Gemini API Error: $e");
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> regenerateSingleQuestion({
    required String documentText,
    required String questionType,
    required String paperCategory,
    String? targetClo,
  }) async {
    String bloomInstruction = _getMasterBloomTaxonomyRules();

    String categoryInstruction = "";
    if (paperCategory == "Theory Based") {
      categoryInstruction = "CRITICAL PAPER STYLE: Focus strictly on definitions, principles, and theoretical concepts. Do NOT invent scenarios.";
    } else if (paperCategory == "Theory + Code/Scenario") {
      categoryInstruction = "CRITICAL PAPER STYLE: Ensure the question leans towards a real-world scenario, case study, or code analysis rather than pure theory.";
    } else if (paperCategory == "Strictly Code/Scenario") {
      categoryInstruction = "CRITICAL PAPER STYLE: This question MUST present a real-world scenario, a case study, or a block of code to analyze. Do NOT ask for simple definitions or direct theoretical recall.";
    }

    String cloInstruction = "";
    String cloJsonField = "";

    if (targetClo != null && targetClo.isNotEmpty) {
      cloInstruction = "CRITICAL RULE: This new question MUST strictly align with this Course Learning Objective: $targetClo.";
      cloJsonField = ',\n        "target_clo": "$targetClo"';
    }

    String formatGuide = "";
    if (questionType == "mcqs") {
      formatGuide = '''
    {
      "question": "New Question?",
      "options": ["Short Option", "One Word", "Max Four Words", "Brief Option"],
      "correctAnswer": "Correct Option"$cloJsonField
    }
    ''';
    } else if (questionType == "fillInTheBlanks") {
      formatGuide = '''
    {
      "question": "The new question with a ________ blank?", 
      "answer": "The correct word"$cloJsonField
    }
    ''';
    } else if (questionType == "shortQuestions") {
      formatGuide = '''
    {
      "question": "New short question?", 
      "idealAnswer": "Ideal answer text"$cloJsonField
    }
    ''';
    } else {
      formatGuide = '''
    {
      "question": "New long question?", 
      "gradingRubric": "Rubric text"$cloJsonField
    }
    ''';
    }

    final prompt = '''
    You are an expert educational assessment generator.
    Generate EXACTLY ONE new, unique question based on the document below.
    
    $bloomInstruction
    
    $categoryInstruction

    Ensure it is completely different from obvious questions.
    $cloInstruction

    Return ONLY a single JSON object (not a list) matching this exact structure:
    $formatGuide

    Document Text:
    """
    $documentText
    """
  ''';

    final model = await _getDynamicModel(isExtraction: false);
    int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        if (text == null || text.isEmpty) return null;
        return jsonDecode(text.replaceAll('```json', '').replaceAll('```', '').trim());
      } catch (e) {
        String errorString = e.toString();
        if (errorString.contains('503') || errorString.contains('429') || errorString.contains('Quota exceeded')) {
          if (attempt == maxRetries) {
            throw Exception("Rate Limit Hit. Please wait a minute before generating again.");
          }
          await Future.delayed(const Duration(seconds: 25));
        } else {
          throw Exception("Gemini Regeneration Error: $e");
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> extractCourseSyllabusFromImage(File imageFile) async {
    final String extractionPrompt = """
      You are a university curriculum data extractor. Analyze this syllabus image.
      Extract the course details, the Credit Hours, and all Course Learning Objectives (CLOs).

      You MUST return ONLY a valid JSON object with the following exact structure, no markdown formatting, no extra text:
      {
        "course_code": "Extracted code (e.g., CS-304)",
        "course_title": "Extracted title (e.g., Object Oriented Programming)",
        "credit_hours": "Extracted credit hours strictly formatted as X(Y-Z), e.g., 4(3-1) or 3(3-0)",
        "clos": [
          {
            "description": "The objective text",
            "domain": "The domain letter (e.g., C for Cognitive)",
            "bt_level": 2, 
            "plo_id": 3 
          }
        ]
      }
      
      CRITICAL: Look closely for credit hours (often written near the title as Cr. Hrs: 3 or 4(3-1)). If the image doesn't explicitly state the credit hours, default it to "3(3-0)". If it doesn't state the course code or title, make your best guess or leave it blank, but preserve the JSON structure. If the domain, bt_level, or plo_id are missing, default them to "C", 2, and 1 respectively.
    """;

    try {
      final model = await _getDynamicModel(isExtraction: true);

      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(extractionPrompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) return null;

      String cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e, stacktrace) {
      throw Exception("Syllabus Extraction Error: $e\n$stacktrace");
    }
  }
}