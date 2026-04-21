import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _savedAssessments = [];

  List<Map<String, dynamic>> get savedAssessments => _savedAssessments;

  HistoryProvider() {
    // 1. THE BULLETPROOF LISTENER
    // This automatically fetches the user's data the exact second they log in,
    // and automatically wipes it the exact second they log out!
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.initialSession || event == AuthChangeEvent.signedIn) {
        loadHistory();
      } else if (event == AuthChangeEvent.signedOut) {
        clearData();
      }
    });
  }

  // --- Load from Supabase Cloud ---
  Future<void> loadHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('assessments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false); // Puts the newest exams at the top!

      _savedAssessments = response.map<Map<String, dynamic>>((row) {
        // We flatten the JSONB content and the DB info together so your existing UI doesn't break!
        final content = Map<String, dynamic>.from(row['content'] as Map);
        content['db_id'] = row['id']; // The unique Supabase row ID used for deleting
        content['title'] = row['title'];
        content['createdAt'] = row['created_at'];
        return content;
      }).toList();

      notifyListeners(); // Instantly populates the Profile stats and History list
    } catch (e) {
      debugPrint("Error loading history from cloud: $e");
    }
  }

  // --- Save to Supabase Cloud ---
  Future<void> saveAssessment(Map<String, dynamic> data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final title = data['title'] ?? "Untitled Assessment";

    try {
      // 1. Insert into Supabase and return the newly created row
      final response = await _supabase.from('assessments').insert({
        'user_id': userId,
        'title': title,
        'content': data, // Swallows your entire generated exam!
      }).select().single();

      // 2. Format the response to match our UI structure
      final newContent = Map<String, dynamic>.from(response['content'] as Map);
      newContent['db_id'] = response['id'];
      newContent['title'] = response['title'];
      newContent['createdAt'] = response['created_at'];

      // 3. Add to the top of our local list so it appears instantly on the screen
      _savedAssessments.insert(0, newContent);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving to cloud: $e");
    }
  }

  // --- Delete from Supabase Cloud ---
  Future<void> deleteAssessment(int index) async {
    if (index < 0 || index >= _savedAssessments.length) return;

    final dbId = _savedAssessments[index]['db_id'];
    if (dbId == null) return;

    // OPTIMISTIC UI UPDATE: Remove it from the screen instantly for a snappy feel
    final removedItem = _savedAssessments.removeAt(index);
    notifyListeners();

    try {
      // Tell Supabase to securely delete the actual row in the background
      await _supabase.from('assessments').delete().eq('id', dbId);
    } catch (e) {
      debugPrint("Error deleting from cloud: $e");
      // If the cloud delete fails (e.g. lost internet), put the item back on the screen!
      _savedAssessments.insert(index, removedItem);
      notifyListeners();
    }
  }

  // --- CLEAR DATA ON LOGOUT ---
  void clearData() {
    _savedAssessments.clear();
    notifyListeners();
  }

  // ==========================================
  // MATH HELPERS FOR THE PROFILE CONTAINERS
  // ==========================================

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