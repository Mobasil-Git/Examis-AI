import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class HistoryProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _savedAssessments = [];

  List<Map<String, dynamic>> get savedAssessments => _savedAssessments;

  HistoryProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
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
        content['created_at'] = row['created_at'];
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
      final response = await _supabase
          .from('assessments')
          .insert({'user_id': userId, 'title': title, 'content': data})
          .select()
          .single();

      final newContent = Map<String, dynamic>.from(response['content'] as Map);
      newContent['db_id'] = response['id'];
      newContent['title'] = response['title'];
      newContent['created_at'] = response['created_at'];

      _savedAssessments.insert(0, newContent);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving to cloud: $e");
    }
  }

  Future<void> deleteAssessment(BuildContext context, int index) async {
    if (index < 0 || index >= _savedAssessments.length) return;

    final dbId = _savedAssessments[index]['db_id'];
    if (dbId == null) return;

    final assessmentToDelete = _savedAssessments[index];
    final removedItem = _savedAssessments.removeAt(index);
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final List<dynamic>? diagramQuestions =
          assessmentToDelete['diagram_questions'];
      int bytesToFree = 0;

      if (diagramQuestions != null && diagramQuestions.isNotEmpty) {
        for (var diag in diagramQuestions) {
          String? exactFileName = diag['file_name'];
          int exactSize = diag['size_bytes'] ?? (800 * 1024);

          if (exactFileName == null && diag['image_url'] != null) {
            String url = diag['image_url'];
            exactFileName = url.split('/').last.split('?').first;
          }

          if (exactFileName != null && exactFileName.isNotEmpty) {
            final deletedObjects = await _supabase.storage
                .from('diagrams')
                .remove([exactFileName]);
            if (deletedObjects.isNotEmpty) {
              debugPrint("✅ Successfully deleted cloud image: $exactFileName");
              bytesToFree += exactSize;
            } else {
              debugPrint(
                "❌ WARNING: Supabase refused to delete $exactFileName. Check RLS policies!",
              );
            }
          }
        }
      }

      await _supabase.from('assessments').delete().eq('id', dbId);

      if (bytesToFree > 0) {
        await _supabase.rpc(
          'increment_storage',
          params: {'user_id': userId, 'bytes_to_add': -bytesToFree},
        );

        if (context.mounted) {
          context.read<AuthProvider>().adjustStorageLocal(-bytesToFree);
        }
        debugPrint("✅ Refunded exactly $bytesToFree bytes.");
      }
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
