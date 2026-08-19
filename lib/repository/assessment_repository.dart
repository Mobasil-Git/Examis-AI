import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AssessmentRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    final response = await _supabase.from('departments').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchBatches() async {
    final response = await _supabase
        .from('batches')
        .select('id, start_year, end_year, batch_name')
        .order('start_year', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createNewBatch(int startYear, int endYear, String batchName) async {
    return await _supabase
        .from('batches')
        .insert({
      'start_year': startYear,
      'end_year': endYear,
      'batch_name': batchName,
    })
        .select()
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchCoursesByBatch(String batchId) async {
    final response = await _supabase
        .from('master_courses')
        .select('id, course_code, title, credit_hours')
        .eq('batch_id', batchId)
        .order('title', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> fetchProfileStorage(String userId) async {
    return await _supabase
        .from('profiles')
        .select('storage_used_bytes, storage_limit_bytes')
        .eq('id', userId)
        .single();
  }

  Future<String> uploadDiagram(String fileName, File imageFile) async {
    await _supabase.storage.from('diagrams').upload(fileName, imageFile);
    return _supabase.storage.from('diagrams').getPublicUrl(fileName);
  }

  Future<void> incrementStorage(String userId, int bytesToAdd) async {
    await _supabase.rpc(
      'increment_storage',
      params: {'user_id': userId, 'bytes_to_add': bytesToAdd},
    );
  }

  Future<List<Map<String, dynamic>>> fetchUserAssessments(String userId) async {
    final response = await _supabase
        .from('assessments')
        .select('id, content, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteDiagrams(List<String> fileNames) async {
    await _supabase.storage.from('diagrams').remove(fileNames);
  }

  Future<void> deleteAssessment(String assessmentId) async {
    await _supabase.from('assessments').delete().eq('id', assessmentId);
  }
}