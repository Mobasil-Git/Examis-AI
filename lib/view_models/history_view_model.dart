import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../repository/history_repository.dart';
import '../repository/google_drive_repository.dart';
import 'auth_view_model.dart';
import 'dart:convert';

class HistoryViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client; // Only for auth listener
  final HistoryRepository _historyRepo = HistoryRepository();
  final GoogleDriveRepository _driveRepo = GoogleDriveRepository();

  List<Map<String, dynamic>> _savedAssessments = [];
  List<Map<String, dynamic>> get savedAssessments => _savedAssessments;

  HistoryViewModel() {
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
      final response = await _historyRepo.loadHistory(userId);
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
      final response = await _historyRepo.saveAssessment(userId, title, data);
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
      final List<dynamic>? diagramQuestions = assessmentToDelete['diagram_questions'];
      int bytesToFree = 0;

      if (diagramQuestions != null && diagramQuestions.isNotEmpty) {
        for (var diag in diagramQuestions) {
          String? exactFileName = diag['file_name'] ?? (diag['image_url'] as String?)?.split('/').last.split('?').first;
          if (exactFileName != null) {
            await _historyRepo.deleteDiagrams([exactFileName]);
            bytesToFree += (diag['size_bytes'] as int?) ?? (800 * 1024);
          }
        }
      }

      await _historyRepo.deleteAssessment(dbId);

      if (bytesToFree > 0) {
        await _historyRepo.adjustStorage(userId, -bytesToFree);
        if (context.mounted) {
          context.read<AuthViewModel>().adjustStorageLocal(-bytesToFree);
        }
      }
    } catch (e) {
      debugPrint("Error deleting from cloud: $e");
      _savedAssessments.insert(index, removedItem);
      notifyListeners();
    }
  }

  Future<bool> backupToDrive(String fileName) async {
    if (_savedAssessments.isEmpty) return false;
    final String jsonContent = const JsonEncoder.withIndent('  ').convert(_savedAssessments);
    return await _driveRepo.backupFileToDrive(fileName: fileName, fileContent: jsonContent);
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