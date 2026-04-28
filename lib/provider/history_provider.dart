import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _savedAssessments = [];

  List<Map<String, dynamic>> get savedAssessments => _savedAssessments;

  HistoryProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.initialSession || event == AuthChangeEvent.signedIn) {
        loadHistory();
      } else if (event == AuthChangeEvent.signedOut) {
        clearData();
      }
    });
  }

  Future<void> loadHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('assessments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _savedAssessments = response.map<Map<String, dynamic>>((row) {
        final content = Map<String, dynamic>.from(row['content'] as Map);
        content['db_id'] = row['id'];
        content['title'] = row['title'];
        content['createdAt'] = row['created_at'];
        return content;
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Error loading history from cloud: $e");
    }
  }

  Future<void> saveAssessment(Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final title = data['title'] ?? "Untitled Assessment";

    try {
      final response = await _supabase.from('assessments').insert({
        'user_id': userId,
        'title': title,
        'content': data,
      }).select().single();

      final newContent = Map<String, dynamic>.from(response['content'] as Map);
      newContent['db_id'] = response['id'];
      newContent['title'] = response['title'];
      newContent['createdAt'] = response['created_at'];

      _savedAssessments.insert(0, newContent);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving to cloud: $e");
    }
  }

  Future<void> deleteAssessment(int index) async {
    if (index < 0 || index >= _savedAssessments.length) return;

    final dbId = _savedAssessments[index]['db_id'];
    if (dbId == null) return;

    final removedItem = _savedAssessments.removeAt(index);
    notifyListeners();

    try {
      await _supabase.from('assessments').delete().eq('id', dbId);
    } catch (e) {
      debugPrint("Error deleting from cloud: $e");
      _savedAssessments.insert(index, removedItem);
      notifyListeners();
    }
  }
  void clearData() {
    _savedAssessments.clear();
    notifyListeners();
  }

  int get totalAssessments => _savedAssessments.length;

  int get totalQuestionsGenerated {
    int count = 0;
    for (var assessment in _savedAssessments) {
      count += (assessment['mcqs'] as List?)?.length ?? 0;
      count += (assessment['shortQuestions'] as List?)?.length ?? 0;
      count += (assessment['longQuestions'] as List?)?.length ?? 0;
    }
    return count;
  }

  int get hoursSaved => (totalAssessments * 45) ~/ 60;
}