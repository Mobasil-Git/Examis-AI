import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:examis_ai/core/secrets.dart';

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
    int mcqCount = 0,
    int shortQCount = 0,
    int longQCount = 0,
  }) async {
    final prompt = '''
      You are an expert educational assessment generator.
      Analyze the following document text and generate a test based strictly on its contents.
      Difficulty level: $difficulty.

      Generate exactly $mcqCount Multiple Choice Questions, $shortQCount Short Answer Questions, and $longQCount Long Essay Questions.

      CRITICAL CONSTRAINT FOR MCQs: The "options" MUST be extremely concise. Keep every single MCQ option strictly between 1 and 4 words maximum. Do not write full sentences for MCQ options.

      You must return the data strictly in the following JSON structure:
      {
        "title": "A short, relevant title for this assessment",
        "mcqs": [
          {
            "question": "The question text here?",
            "options": ["Short Option", "One Word", "Max Four Words", "Brief Option"],
            "correctAnswer": "The exact text of the correct option"
          }
        ],
        "shortQuestions": [
          {
            "question": "The short answer question text?",
            "idealAnswer": "A brief, accurate ideal answer based on the text"
          }
        ],
        "longQuestions": [
          {
            "question": "The long essay question text?",
            "gradingRubric": "A brief guide on what a correct answer should include"
          }
        ]
      }

      Document Text:
      """
      $documentText
      """
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text == null || response.text!.isEmpty) return null;
      return jsonDecode(response.text!);
    } catch (e) {
      print("Gemini Generation Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> regenerateSingleQuestion({
    required String documentText,
    required String difficulty,
    required String questionType,
  }) async {
    String formatGuide = "";
    if (questionType == "mcqs") {
      formatGuide = '''
      {
        "question": "New Question?",
        "options": ["Short Option", "One Word", "Max Four Words", "Brief Option"],
        "correctAnswer": "Correct Option"
      }

      CRITICAL CONSTRAINT: Keep all MCQ options strictly between 1 and 4 words maximum!
      ''';
    } else if (questionType == "shortQuestions") {
      formatGuide =
      '{"question": "New short question?", "idealAnswer": "Ideal answer text"}';
    } else {
      formatGuide =
      '{"question": "New long question?", "gradingRubric": "Rubric text"}';
    }

    final prompt = '''
      You are an expert educational assessment generator.
      Generate EXACTLY ONE new, unique question based on the document below.
      Difficulty level: $difficulty.

      Ensure it is completely different from obvious questions.

      Return ONLY a single JSON object (not a list) matching this exact structure:
      $formatGuide

      Document Text:
      """
      $documentText
      """
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text == null || response.text!.isEmpty) return null;
      return jsonDecode(response.text!);
    } catch (e) {
      print("Single Generation Error: $e");
      return null;
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