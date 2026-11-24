import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/template_repository.dart';

class TemplateState {
  final int totalTemplates;
  final List<Map<String, dynamic>> templates;
  final bool isLoading;

  const TemplateState({
    this.totalTemplates = 0,
    this.templates = const [],
    this.isLoading = false,
  });

  TemplateState copyWith({
    int? totalTemplates,
    List<Map<String, dynamic>>? templates,
    bool? isLoading,
  }) {
    return TemplateState(
      totalTemplates: totalTemplates ?? this.totalTemplates,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TemplateNotifier extends Notifier<TemplateState> {
  final TemplateRepository _templateRepo = TemplateRepository();

  @override
  TemplateState build() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        fetchTemplateCount();
      } else if (event == AuthChangeEvent.signedOut) {
        state = const TemplateState();
      }
    });

    if (Supabase.instance.client.auth.currentUser != null) {
      fetchTemplateCount();
    }

    return const TemplateState();
  }

  Future<void> fetchTemplateCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(totalTemplates: 0);
        return;
      }
      final response = await _templateRepo.fetchExistingTemplates(userId);
      state = state.copyWith(totalTemplates: response.length);
    } catch (e) {
      debugPrint("Error fetching templates count: $e");
    }
  }

  Future<void> fetchTemplates() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final templates = await _templateRepo.fetchUserInstitutes(userId);
        state = state.copyWith(templates: templates, isLoading: false);
        return;
      }
    } catch (e) {
      debugPrint("Error fetching templates: $e");
    }
    state = state.copyWith(isLoading: false);
  }

  Future<bool> deleteTemplate(dynamic id) async {
    try {
      final response = await _templateRepo.fetchInstituteById(id);
      final String? templateUrl = response['template_url'];

      if (templateUrl != null && templateUrl.isNotEmpty) {
        Uri uri = Uri.parse(templateUrl);
        String fileName = uri.pathSegments.last;
        await _templateRepo.deleteTemplateFile(fileName);
      }

      final deletedRow = await _templateRepo.deleteInstituteRecord(id);
      if (deletedRow.isNotEmpty) {
        final updatedTemplates =
            List<Map<String, dynamic>>.from(state.templates)..removeWhere(
              (template) => template['id'].toString() == id.toString(),
            );

        state = state.copyWith(
          templates: updatedTemplates,
          totalTemplates: updatedTemplates.length,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("CRITICAL Delete Institute Error: $e");
      return false;
    }
  }
}

final templateProvider = NotifierProvider<TemplateNotifier, TemplateState>(() {
  return TemplateNotifier();
});
