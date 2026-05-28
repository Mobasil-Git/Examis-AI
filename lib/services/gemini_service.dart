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

  String _getMasterBloomTaxonomyRules() {
    return """
    UNIVERSAL EDUCATIONAL STANDARDS (STRICT ENFORCEMENT):
    You must match the cognitive difficulty and the educational domain of EVERY single generated question to the exact 'Domain' and 'BT Level' specified in its assigned CLO.

    --- DOMAIN RULES ---
    1. Cognitive Domain: The question must test mental skills, theory, recall, and logical analysis.
    2. Psychomotor Domain: The question MUST require the student to actively "do" something physical. In the context of Computer Science, this strictly means writing raw code, physically tracing an algorithm, or drafting a concrete technical diagram.
    3. Affective Domain: The question must test the student's attitude, professional ethics, or understanding of societal impact.

    --- BLOOM'S TAXONOMY RULES ---
    [LEVELS 1 & 2: EASY (Knowledge & Comprehension)]
    - Focus: Remember previously learned information and demonstrate an understanding of the facts.
    - Verbs to use: Define, Describe, Duplicate, Identify, Label, List, Match, Memorize, Name, Order, Outline, Recognize, Relate, Recall, Repeat, Reproduce, Select, State, Classify, Convert, Defend, Discuss, Distinguish, Estimate, Explain, Express, Extend, Generalized, Give example(s), Indicate, Infer, Locate, Paraphrase, Predict, Rewrite, Review, Summarize, and Translate.

    [LEVELS 3 & 4: MEDIUM (Application & Analysis)]
    - Focus: Apply knowledge to actual situations, break down objects or ideas into simpler parts, and find evidence to support generalizations.
    - Verbs to use: Apply, Change, Choose, Compute, Demonstrate, Discover, Dramatize, Employ, Illustrate, Interpret, Manipulate, Modify, Operate, Practice, Predict, Prepare, Produce, Relate, Schedule, Show, Sketch, Solve, Use, Write, Analyze, Appraise, Breakdown, Calculate, Categorize, Compare, Contrast, Criticize, Diagram, Differentiate, Discriminate, Distinguish, Examine, Experiment, Identify, Infer, Model, Outline, Point out, Question, Select, Separate, Subdivide, and Test.

    [LEVELS 5 & 6: HARD (Synthesis & Evaluation)]
    - Focus: Compile component ideas into a new whole or propose alternative solutions, and make and defend judgments based on internal evidence or external criteria.
    - Verbs to use: Arrange, Assemble, Categorize, Collect, Combine, Comply, Compose, Construct, Create, Design, Develop, Devise, Explain, Formulate, Generate, Plan, Prepare, Rearrange, Reconstruct, Relate, Reorganize, Revise, Rewrite, Set up, Summarize, Synthesize, Tell, Write, Appraise, Argue, Assess, Attach, Choose, Compare, Conclude, Contrast, Defend, Describe, Discriminate, Estimate, Evaluate, Judge, Justify, Interpret, Predict, Rate, Select, Support, and Value.
    """;
  }

  Future<Map<String, dynamic>?> generateAssessment({
    required String documentText,
    required String paperCategory,
    int mcqCount = 0,
    int shortQCount = 0,
    int longQCount = 0,
    int fillBlankCount = 0,
    List<String> activeCLOs = const [],
    bool letAIGenerateScenario = true,
    List<Map<String, dynamic>> customScenarios = const [],
    List<Map<String, dynamic>> diagramQuestions = const [],
  }) async {
    String bloomInstruction = _getMasterBloomTaxonomyRules();

    String cloPromptSection = "";
    String cloJsonField = "";

    if (activeCLOs.isNotEmpty) {
      cloPromptSection =
      """
      COURSE LEARNING OBJECTIVES (CLOs):
      ${activeCLOs.join('\n')}

      CRITICAL CLO DISTRIBUTION RULES:
      You are strictly required to map EVERY generated question to one of the CLOs listed above. 
      1. Uniform Coverage: For each section (MCQs, Short Questions, Long Questions), you MUST generate one question per CLO before you are allowed to reuse a CLO. 
      2. The Overflow Rule: If a section requires more questions than available CLOs, map the first questions to the available CLOs respectively. Assign the remaining questions to the most fundamentally important CLO.
      3. The Distinct Rule (No Duplication): If a section requires fewer questions than available CLOs, you MUST pick distinct CLOs. Never assign the same CLO to two questions in the same section unless you have already used every single CLO at least once in that section.
      4. JSON Output: Every single question object in your JSON response MUST include a "target_clo" key containing the exact CLO identifier provided above (e.g., "CLO 3").
      """;

      cloJsonField = ',\n            "target_clo": "CLO X"';
    }

    String categoryInstruction = "";
    if (paperCategory == "Theory Based") {
      categoryInstruction =
      "CRITICAL PAPER STYLE: Focus strictly on definitions, principles, and theoretical concepts. Do NOT invent scenarios.";
    } else if (paperCategory == "Theory + Code/Scenario") {
      categoryInstruction =
      "CRITICAL PAPER STYLE: Generate a balanced mix. Half the questions should test theoretical recall, and the other half MUST present a short real-world scenario or a block of code to analyze.";
    } else if (paperCategory == "Strictly Code/Scenario") {
      categoryInstruction =
      "CRITICAL PAPER STYLE: Every single question MUST present a real-world scenario, a case study, or a block of code to analyze. Do NOT ask for simple definitions or direct theoretical recall.";
    }

    String scenarioInstruction = "";
    String scenarioJsonField = "";

    if (paperCategory != "Theory Based" && customScenarios.isNotEmpty) {
      // 🚀 THE FIX: Strict Guardrails based on the user's explicit selection
      String formattedRequests = customScenarios.asMap().entries.map((e) {
        final sc = e.value;
        if (sc['type'] == 'Code') {
          return "Item ${e.key + 1} (Marks: ${sc['marks']}): STRICT CODE GENERATION. Language: ${sc['language']}. Topic/Hint: ${sc['text']}. You MUST output pure, executable code. DO NOT write a story, narrative, or scenario.";
        } else {
          return "Item ${e.key + 1} (Marks: ${sc['marks']}): STRICT SCENARIO GENERATION. Topic/Hint: ${sc['text']}. You MUST output a text-based real-world scenario or case study. DO NOT generate code blocks.";
        }
      }).join("\n\n");

      if (letAIGenerateScenario) {
        scenarioInstruction =
        """
        SCENARIO & CODE RULES: You MUST generate ${customScenarios.length} items based EXACTLY on the following instructions.
        
        CRITICAL CONSTRAINTS:
        1. If an item is marked as STRICT CODE GENERATION, you are strictly forbidden from writing paragraph text. Output only the requested code.
        2. If an item is marked as STRICT SCENARIO GENERATION, you must write a realistic problem description. Output only text, no code.
        
        [TEACHER INSTRUCTIONS]
        $formattedRequests
        """;
      } else {
        scenarioInstruction =
        "SCENARIO RULE: You MUST use the EXACT text provided below for the scenarios. Do not change them.\n[EXACT TEXT]\n$formattedRequests";
      }

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

    String diagramInstruction = "";
    String diagramJsonField = "";

    if (diagramQuestions.isNotEmpty) {
      String formattedDiagrams = diagramQuestions
          .asMap()
          .entries
          .map(
            (e) =>
        "Diagram Question ${e.key + 1} (Marks: ${e.value['marks']}, URL: ${e.value['image_url']}): ${e.value['question']}",
      )
          .join("\n");

      diagramInstruction =
      """
      DIAGRAM QUESTIONS RULE: The teacher has provided pre-written diagram-based questions.
      You MUST strictly pass these EXACT questions through to the final JSON under the "diagram_questions" array.
      Do not change the text or the URLs.
      [TEACHER DIAGRAMS]
      $formattedDiagrams
      """;

      diagramJsonField =
      '''
        ,
        "diagram_questions": [
          {
            "question": "The exact question text provided",
            "image_url": "The exact image_url provided",
            "marks": 5$cloJsonField
          }
        ]
      ''';
    }

    final prompt =
    '''
      You are an expert educational assessment generator.
      Analyze the following document text and generate a test based strictly on its contents.
      
      $bloomInstruction
      
      $categoryInstruction
      $scenarioInstruction
      $diagramInstruction

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
        ]$diagramJsonField
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

        if (e.toString().contains('503') || e.toString().contains('429')) {
          if (attempt == maxRetries) {
            print("Max retries reached. Failing gracefully.");
            return null;
          }
          int delaySeconds = attempt * 2;
          print("Waiting $delaySeconds seconds before retrying...");
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          return null;
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
      categoryInstruction =
      "CRITICAL PAPER STYLE: Focus strictly on definitions, principles, and theoretical concepts. Do NOT invent scenarios.";
    } else if (paperCategory == "Theory + Code/Scenario") {
      categoryInstruction =
      "CRITICAL PAPER STYLE: Ensure the question leans towards a real-world scenario, case study, or code analysis rather than pure theory.";
    } else if (paperCategory == "Strictly Code/Scenario") {
      categoryInstruction =
      "CRITICAL PAPER STYLE: This question MUST present a real-world scenario, a case study, or a block of code to analyze. Do NOT ask for simple definitions or direct theoretical recall.";
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
      formatGuide =
      '''
    {
      "question": "New Question?",
      "options": ["Short Option", "One Word", "Max Four Words", "Brief Option"],
      "correctAnswer": "Correct Option"$cloJsonField
    }
    ''';
    } else if (questionType == "fillInTheBlanks") {
      formatGuide =
      '''
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

    int maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _model.generateContent([Content.text(prompt)]);
        if (response.text == null || response.text!.isEmpty) return null;
        return jsonDecode(response.text!);
      } catch (e) {
        print("Gemini Generation Error on attempt $attempt: $e");
        String errorString = e.toString();

        if (errorString.contains('503') ||
            errorString.contains('429') ||
            errorString.contains('Quota exceeded')) {
          if (attempt == maxRetries) {
            throw Exception(
              "Rate Limit Hit. Please wait a minute before generating again.",
            );
          }

          int delaySeconds = 25;
          print(
            "Rate limit hit! Waiting $delaySeconds seconds for Google servers to cool down...",
          );
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          return null;
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> extractCourseSyllabusFromImage(
      File imageFile,
      ) async {
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
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(extractionPrompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) return null;

      String cleanJson = response.text!
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      print("Syllabus Extraction Error: $e");
      return null;
    }
  }
}