import 'dart:convert';
import 'package:examisai/view_models/assessment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_provider.dart';

class CourseCatalogState {
  final List<Map<String, dynamic>> availableBatches;
  final Map<String, dynamic>? selectedBatch;
  final List<Map<String, dynamic>> departments;
  final Map<String, dynamic>? generalDepartment;

  final String? importedCourseCode;
  final String? importedCourseTitle;
  final List<Map<String, dynamic>> importedClos;
  final String courseCreditHours;
  final String? selectedDepartmentName;

  const CourseCatalogState({
    this.availableBatches = const [],
    this.selectedBatch,
    this.departments = const [],
    this.generalDepartment,
    this.importedCourseCode,
    this.importedCourseTitle,
    this.importedClos = const [],
    this.courseCreditHours = "3(3-0)",
    this.selectedDepartmentName,
  });

  CourseCatalogState copyWith({
    List<Map<String, dynamic>>? availableBatches,
    Map<String, dynamic>? selectedBatch,
    List<Map<String, dynamic>>? departments,
    Map<String, dynamic>? generalDepartment,
    String? importedCourseCode,
    String? importedCourseTitle,
    List<Map<String, dynamic>>? importedClos,
    String? courseCreditHours,
    String? selectedDepartmentName,
  }) {
    return CourseCatalogState(
      availableBatches: availableBatches ?? this.availableBatches,
      selectedBatch: selectedBatch ?? this.selectedBatch,
      departments: departments ?? this.departments,
      generalDepartment: generalDepartment ?? this.generalDepartment,
      importedCourseCode: importedCourseCode ?? this.importedCourseCode,
      importedCourseTitle: importedCourseTitle ?? this.importedCourseTitle,
      importedClos: importedClos ?? this.importedClos,
      courseCreditHours: courseCreditHours ?? this.courseCreditHours,
      selectedDepartmentName:
          selectedDepartmentName ?? this.selectedDepartmentName,
    );
  }
}

class CourseCatalogNotifier extends Notifier<CourseCatalogState> {
  final _supabase = Supabase.instance.client;

  @override
  CourseCatalogState build() {
    return const CourseCatalogState();
  }

  Future<void> fetchBatches() async {
    try {
      final data = await _supabase
          .from('batches')
          .select()
          .order('start_year', ascending: false);
      final batches = List<Map<String, dynamic>>.from(data);
      state = state.copyWith(
        availableBatches: batches,
        selectedBatch: batches.isNotEmpty ? batches.first : null,
      );
    } catch (e) {
      debugPrint("Error fetching batches: $e");
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final data = await _supabase
          .from('departments')
          .select()
          .order('name', ascending: true);
      final depts = List<Map<String, dynamic>>.from(data);
      final generalDept = depts.firstWhere(
        (d) => d['name'].toString().contains('General'),
        orElse: () => <String, dynamic>{},
      );

      state = state.copyWith(
        departments: depts,
        generalDepartment: generalDept.isNotEmpty ? generalDept : null,
      );
    } catch (e) {
      debugPrint("Error fetching departments: $e");
    }
  }

  void updateSelectedBatch(Map<String, dynamic> batch) {
    state = state.copyWith(selectedBatch: batch);
  }

  Future<bool> createNewBatch(int startYear, int endYear) async {
    final batchName = "$startYear-$endYear";
    try {
      final existing = await _supabase
          .from('batches')
          .select()
          .eq('batch_name', batchName)
          .maybeSingle();
      if (existing != null) return false;

      await _supabase.from('batches').insert({
        'start_year': startYear,
        'end_year': endYear,
        'batch_name': batchName,
      });
      await fetchBatches();
      return true;
    } catch (e) {
      debugPrint("Error creating batch: $e");
      return false;
    }
  }

  // Inside CourseCatalogNotifier in lib/view_models/course_catalog_provider.dart:
  void setImportedCourse(
    String code,
    String title,
    List<Map<String, dynamic>> clos,
    String creditHrs,
    String deptName,
  ) {
    state = state.copyWith(
      importedCourseCode: code,
      importedCourseTitle: title,
      importedClos: clos,
      courseCreditHours: creditHrs,
      selectedDepartmentName: deptName,
    );

    ref
        .read(assessmentProvider.notifier)
        .setImportedCourse(code, title, clos, creditHrs, deptName);
  }

  Future<Map<String, dynamic>?> extractCourseWithGemini(XFile image) async {
    final apiKey = ref.read(authProvider).customApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        "Gemini API key is missing. Please configure it in BYOK Settings.",
      );
    }

    final model = GenerativeModel(model: 'gemini-3.6-flash', apiKey: apiKey);
    final bytes = await image.readAsBytes();

    String mimeType = 'image/jpeg';
    final lowerName = image.name.toLowerCase();
    if (lowerName.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (lowerName.endsWith('.webp')) {
      mimeType = 'image/webp';
    } else if (lowerName.endsWith('.heic')) {
      mimeType = 'image/heic';
    }

    final prompt = TextPart(
      "Analyze this syllabus image. Extract the following and return ONLY a valid raw JSON object (no markdown tags): "
      "{ 'course_code': 'string', 'course_title': 'string', 'credit_hours': 'string (e.g., 3(3-0))', "
      "'clos': [ { 'description': 'string', 'domain': 'C or P or A', 'bt_level': int (1-6), 'plo_id': int (1-12) } ] }.",
    );

    try {
      final response = await model.generateContent([
        Content.multi([prompt, DataPart(mimeType, bytes)]),
      ]);

      final text = response.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      if (text != null) {
        return jsonDecode(text) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Gemini Extraction Error: $e");
      throw Exception(
        "AI Extraction failed. Ensure your image is clear and the API key is valid.",
      );
    }
    return null;
  }
}

final courseCatalogProvider =
    NotifierProvider<CourseCatalogNotifier, CourseCatalogState>(() {
      return CourseCatalogNotifier();
    });
