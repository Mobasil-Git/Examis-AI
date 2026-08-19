import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadHistory(String userId) async {
    final response = await _supabase
        .from('assessments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> saveAssessment(String userId, String title, Map<String, dynamic> data) async {
    return await _supabase
        .from('assessments')
        .insert({
      'user_id': userId,
      'title': title,
      'content': data,
    })
        .select()
        .single();
  }

  Future<void> deleteAssessment(String dbId) async {
    await _supabase.from('assessments').delete().eq('id', dbId);
  }

  Future<void> deleteDiagrams(List<String> fileNames) async {
    await _supabase.storage.from('diagrams').remove(fileNames);
  }

  Future<void> adjustStorage(String userId, int bytesToAdd) async {
    await _supabase.rpc(
      'increment_storage',
      params: {'user_id': userId, 'bytes_to_add': bytesToAdd},
    );
  }
}