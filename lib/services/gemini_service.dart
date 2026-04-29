import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:examis_ai/core/secrets.dart';
import 'dart:io';

class GeminiService {
  final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: AppSecrets.geminiApiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.1,
    ),
  );

  Future<Map<String, dynamic>?> generateAssessment({
    required String documentText,
    required String difficulty,
    required String paperCategory,
    int mcqCount = 0,
    int shortQCount = 0,
    int longQCount = 0,
    int fillBlankCount = 0,
    List<String> activeCLOs = const [],
    bool letAIGenerateScenario = true, // <--- NEW
    List<Map<String, dynamic>> customScenarios = const [],
    String customScenario = "", // <--- NEW
  }) async {
    String cloPromptSection = "";
    String cloJsonField = "";

    if (activeCLOs.isNotEmpty) {
      cloPromptSection =
          """
      COURSE LEARNING OBJECTIVES (CLOs):
      ${activeCLOs.asMap().entries.map((e) => "CLO ${e.key + 1}: ${e.value}").join('\n')}

      CRITICAL CLO DISTRIBUTION RULES:
      You are strictly required to map EVERY generated question to one of the CLOs listed above. 
      1. Uniform Coverage: For each section (MCQs, Short Questions, Long Questions), you MUST generate one question per CLO before you are allowed to reuse a CLO. 
      2. The Overflow Rule: If a section requires more questions than available CLOs (e.g., 4 questions, 3 CLOs), map the first 3 questions to CLO 1, CLO 2, and CLO 3 respectively. Assign the 4th question to the most fundamentally important CLO.
      3. The Distinct Rule (No Duplication): If a section requires fewer questions than available CLOs (e.g., 2 Long Questions, 3 CLOs), you MUST pick distinct CLOs. Never assign the same CLO to two questions in the same section unless you have already used every single CLO at least once in that section.
      4. JSON Output: Every single question object in your JSON response MUST include a "target_clo" key containing the exact CLO identifier (e.g., "CLO 1").
      """;

      cloJsonField = ',\n            "target_clo": "CLO 1"';
    }

    // 2. Build the Paper Category Constraint
    String categoryInstruction = "";
    if (paperCategory == "Theory Based") {
      categoryInstruction = "CRITICAL PAPER STYLE: Focus strictly on definitions, principles, and theoretical concepts. Do NOT invent scenarios.";
    } else if (paperCategory == "Theory + Code/Scenario") {
      categoryInstruction = "CRITICAL PAPER STYLE: Generate a balanced mix. Half the questions should test theoretical recall, and the other half MUST present a short real-world scenario or a block of code to analyze.";
    } else if (paperCategory == "Strictly Code/Scenario") {
      categoryInstruction = "CRITICAL PAPER STYLE: Every single question MUST present a real-world scenario, a case study, or a block of code to analyze. Do NOT ask for simple definitions or direct theoretical recall.";
    }

    // 3. Build the Custom Scenario Constraint
    String scenarioInstruction = "";
    String scenarioJsonField = "";

    if (paperCategory != "Theory Based" && customScenarios.isNotEmpty) {
      // Create a formatted string of what the teacher requested
      String formattedRequests = customScenarios.asMap().entries.map((e) {
        return "Scenario ${e.key + 1} (Marks: ${e.value['marks']}): ${e.value['text']}";
      }).join("\n");

      if (letAIGenerateScenario) {
        scenarioInstruction = """
        SCENARIO RULE: You MUST generate ${customScenarios.length} scenarios or code blocks based on the following hints.
        
        CRITICAL CONSTRAINTS FOR GENERATION:
        1. If the hint asks for a scenario or case study, write a clear, text-based narrative story or problem description.
        2. If the hint asks for code, you MUST output pure, fresh code. You are STRICTLY FORBIDDEN from adding any code comments (e.g., no //, no /* */, no #) unless the teacher's hint specifically asks you to include them. Do not explain the code inside the code block.
        
        [TEACHER HINTS]
        $formattedRequests
        """;
      } else {
        scenarioInstruction = "SCENARIO RULE: You MUST use the EXACT text provided below for the scenarios. Do not change them. Base your questions strictly on these.\n[EXACT TEXT]\n$formattedRequests";
      }

      // Force Gemini to output the scenarios back to us!
      scenarioJsonField = '''
        ,
        "custom_scenarios": [
          {
            "text": "The full scenario text or code block...",
            "marks": 10
          }
        ]
      ''';
    }

    final prompt =
        '''
      You are an expert educational assessment generator.
      Analyze the following document text and generate a test based strictly on its contents.
      Difficulty level: $difficulty.
      $categoryInstruction
      $scenarioInstruction

      Generate exactly $mcqCount Multiple Choice Questions, $fillBlankCount Fill in the Blank Questions, $shortQCount Short Answer Questions, and $longQCount Long Essay Questions.

      CRITICAL CONSTRAINT FOR MCQs: The "options" MUST be extremely concise. Keep every single MCQ option strictly between 1 and 4 words maximum. Do not write full sentences for MCQ options.

      $cloPromptSection

      You must return the data strictly in the following JSON structure:
      {
        "title": "A short, relevant title for this assessment"$scenarioJsonField,
        "mcqs": [
          {
            "question": "The question text here?",
            "options": ["Short Option", "One Word", "Max Four Words", "Brief Option"],
            "correctAnswer": "The exact text of the correct option"$cloJsonField
          }
        ],
        "fillInTheBlanks": [
          {
            "question": "The capital of France is ________.",
            "answer": "Paris"$cloJsonField
          }
        ],
        "shortQuestions": [
          {
            "question": "The short answer question text?",
            "idealAnswer": "A brief, accurate ideal answer based on the text"$cloJsonField
          }
        ],
        "longQuestions": [
          {
            "question": "The long essay question text?",
            "gradingRubric": "A brief guide on what a correct answer should include"$cloJsonField
          }
        ]
      }

      Document Text:
      """
      $documentText
      """
    ''';
    int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print("Gemini API Attempt $attempt of $maxRetries...");
        final response = await _model.generateContent([Content.text(prompt)]);

        if (response.text == null || response.text!.isEmpty) return null;

        return jsonDecode(response.text!);
      } catch (e) {
        print("Gemini Generation Error on attempt $attempt: $e");

        // If it's a 503 or 429 (Too Many Requests) error, we wait and try again
        if (e.toString().contains('503') || e.toString().contains('429')) {
          if (attempt == maxRetries) {
            print("Max retries reached. Failing gracefully.");
            return null; // Give up after 3 tries so the app doesn't hang forever
          }

          // Wait for 2 seconds on the first fail, 4 seconds on the second fail...
          int delaySeconds = attempt * 2;
          print("Waiting $delaySeconds seconds before retrying...");
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          // If it's a different kind of error (like a JSON formatting issue), fail immediately
          return null;
        }
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> regenerateSingleQuestion({
    required String documentText,
    required String difficulty,
    required String questionType,
    required String paperCategory, // <--- 1. NEW PARAMETER
    String? targetClo,
  }) async {

    // ==========================================
    // 2. Build the Paper Category Constraint
    // ==========================================
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
      cloInstruction =
      "CRITICAL RULE: This new question MUST strictly align with this Course Learning Objective: $targetClo.";
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
      formatGuide =
      '''
    {
      "question": "New short question?", 
      "idealAnswer": "Ideal answer text"$cloJsonField
    }
    ''';
    } else {
      formatGuide =
      '''
    {
      "question": "New long question?", 
      "gradingRubric": "Rubric text"$cloJsonField
    }
    ''';
    }

    final prompt =
    '''
    You are an expert educational assessment generator.
    Generate EXACTLY ONE new, unique question based on the document below.
    Difficulty level: $difficulty.
    
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

    int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        if (response.text == null || response.text!.isEmpty) return null;
        return jsonDecode(response.text!);
      } catch (e) {
        print("Gemini Generation Error on attempt $attempt: $e");
        String errorString = e.toString();

        if (errorString.contains('503') || errorString.contains('429') || errorString.contains('Quota exceeded')) {
          if (attempt == maxRetries) {
            throw Exception("Rate Limit Hit. Please wait a minute before generating again.");
          }

          // 👇 CHANGED: Wait 25 seconds to guarantee we clear Google's 20-second timeout 👇
          int delaySeconds = 25;
          print("Rate limit hit! Waiting $delaySeconds seconds for Google servers to cool down...");
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          return null;
        }
      }
    }
    return null;
  }

  Future<List<String>> extractCLOsFromImage(File imageFile) async {
    final prompt = '''
      You are an expert curriculum assistant. 
      Analyze this image (which is likely a syllabus or exam paper) and extract all Course Learning Objectives (CLOs), Learning Outcomes, or main topics.
      
      CRITICAL RULE: Return ONLY a valid JSON array of strings. Do not include markdown formatting like ```json. Do not say "Here are the CLOs". 
      
      Example output format:
      ["Understand the basics of OOP", "Apply polymorphism in Java", "Analyze time complexity"]
    ''';

    try {
      final imageBytes = await imageFile.readAsBytes();

      // We pass BOTH text and image data to Gemini
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) return [];

      // Clean the response just in case Gemini disobeys and adds markdown
      String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();

      List<dynamic> parsedList = jsonDecode(cleanJson);
      return parsedList.map((e) => e.toString()).toList();

    } catch (e) {
      print("Vision Extraction Error: $e");
      return [];
    }
  }
}

// class GeminiService {
//   // --- MOCK FULL GENERATION ---
//   Future<Map<String, dynamic>?> generateAssessment({
//     required String documentText,
//     required String difficulty,
//     int mcqCount = 0,
//     int shortQCount = 0,
//     int longQCount = 0,
//   }) async {
//     // Fake a 3-second network loading time
//     await Future.delayed(const Duration(seconds: 3));
//
//     return {
//       "title": "Mock App Testing Assessment",
//       "mcqs": List.generate(mcqCount, (index) => {
//         "question": "This is a fake AI question number ${index + 1}?",
//         "options": ["Fake A", "Fake B", "Fake C", "Fake D"],
//         "correctAnswer": "Fake A"
//       }),
//       "shortQuestions": List.generate(shortQCount, (index) => {
//         "question": "Fake short question ${index + 1}?",
//         "idealAnswer": "This is a fake ideal answer for testing."
//       }),
//       "longQuestions": List.generate(longQCount, (index) => {
//         "question": "Fake long essay question ${index + 1}?",
//         "gradingRubric": "Look for the fake keywords in the answer."
//       })
//     };
//   }
//
//   // --- MOCK SINGLE REGENERATION ---
//   Future<Map<String, dynamic>?> regenerateSingleQuestion({
//     required String documentText,
//     required String difficulty,
//     required String questionType,
//   }) async {
//     // Fake a 2-second loading time to test your cool skeleton animation!
//     await Future.delayed(const Duration(seconds: 2));
//
//     if (questionType == "mcqs") {
//       return {
//         "question": "FRESHLY REGENERATED MCQ! IT WORKS!",
//         "options": ["New A", "New B", "New C", "New D"],
//         "correctAnswer": "New A"
//       };
//     } else if (questionType == "shortQuestions") {
//       return {
//         "question": "FRESHLY REGENERATED SHORT QUESTION!",
//         "idealAnswer": "Fresh fake answer."
//       };
//     } else {
//       return {
//         "question": "FRESHLY REGENERATED LONG QUESTION!",
//         "gradingRubric": "Fresh fake rubric."
//       };
//     }
//   }
// }
