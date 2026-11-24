import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/history_repository.dart';
import '../repository/google_drive_repository.dart';
import 'auth_provider.dart';

class HistoryState {
  final List<Map<String, dynamic>> savedAssessments;

  const HistoryState({this.savedAssessments = const []});

  HistoryState copyWith({List<Map<String, dynamic>>? savedAssessments}) {
    return HistoryState(
      savedAssessments: savedAssessments ?? this.savedAssessments,
    );
  }

  int get totalAssessments => savedAssessments.length;

  int get totalQuestionsGenerated {
    int count = 0;
    for (var assessment in savedAssessments) {
      count += (assessment['mcqs'] as List?)?.length ?? 0;
      count += (assessment['shortQuestions'] as List?)?.length ?? 0;
      count += (assessment['longQuestions'] as List?)?.length ?? 0;
    }
    return count;
  }

  int get hoursSaved => (totalAssessments * 45) ~/ 60;
}

class HistoryNotifier extends Notifier<HistoryState> {
  final _supabase = Supabase.instance.client;
  final HistoryRepository _historyRepo = HistoryRepository();
  final GoogleDriveRepository _driveRepo = GoogleDriveRepository();

  @override
  HistoryState build() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.signedIn) {
        loadHistory();
      } else if (event == AuthChangeEvent.signedOut) {
        clearData();
      }
    });

    if (_supabase.auth.currentUser != null) {
      loadHistory();
    }
    return const HistoryState();
  }

  Future<void> loadHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await _historyRepo.loadHistory(userId);
      final loaded = response.map<Map<String, dynamic>>((row) {
        final content = Map<String, dynamic>.from(row['content'] as Map);
        content['db_id'] = row['id'];
        content['title'] = row['title'];
        content['created_at'] = row['created_at'];
        return content;
      }).toList();
      state = state.copyWith(savedAssessments: loaded);
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

      state = state.copyWith(
        savedAssessments: [newContent, ...state.savedAssessments],
      );
    } catch (e) {
      debugPrint("Error saving to cloud: $e");
    }
  }

  Future<void> deleteAssessment(int index) async {
    if (index < 0 || index >= state.savedAssessments.length) return;

    final dbId = state.savedAssessments[index]['db_id'];
    if (dbId == null) return;

    final assessmentToDelete = state.savedAssessments[index];

    // Optimistic UI update
    final updatedList = List<Map<String, dynamic>>.from(state.savedAssessments)
      ..removeAt(index);
    state = state.copyWith(savedAssessments: updatedList);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final List<dynamic>? diagramQuestions =
          assessmentToDelete['diagram_questions'];
      int bytesToFree = 0;

      if (diagramQuestions != null && diagramQuestions.isNotEmpty) {
        for (var diag in diagramQuestions) {
          String? exactFileName =
              diag['file_name'] ??
              (diag['image_url'] as String?)?.split('/').last.split('?').first;
          if (exactFileName != null) {
            await _historyRepo.deleteDiagrams([exactFileName]);
            bytesToFree += (diag['size_bytes'] as int?) ?? (800 * 1024);
          }
        }
      }

      await _historyRepo.deleteAssessment(dbId);

      if (bytesToFree > 0) {
        await _historyRepo.adjustStorage(userId, -bytesToFree);
        ref.read(authProvider.notifier).adjustStorageLocal(-bytesToFree);
      }
    } catch (e) {
      debugPrint("Error deleting from cloud: $e");
      final rollbackList = List<Map<String, dynamic>>.from(
        state.savedAssessments,
      )..insert(index, assessmentToDelete);
      state = state.copyWith(savedAssessments: rollbackList);
    }
  }

  Future<bool> backupToDrive(String fileName) async {
    if (state.savedAssessments.isEmpty) return false;
    final String jsonContent = const JsonEncoder.withIndent(
      '  ',
    ).convert(state.savedAssessments);
    return await _driveRepo.backupFileToDrive(
      fileName: fileName,
      fileContent: jsonContent,
    );
  }

  void clearData() {
    state = const HistoryState();
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(() {
  return HistoryNotifier();
});
