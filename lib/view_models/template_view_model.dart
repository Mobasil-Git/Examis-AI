import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/template_repository.dart';

class TemplateViewModel extends ChangeNotifier {
  final TemplateRepository _templateRepo = TemplateRepository();
  int _totalTemplates = 0;
  List<Map<String, dynamic>> templates = [];
  bool isLoading = false;

  int get totalTemplates => _totalTemplates;

  TemplateViewModel() {
    fetchTemplateCount();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        fetchTemplateCount();
      } else if (event == AuthChangeEvent.signedOut) {
        _totalTemplates = 0;
        notifyListeners();
      }
    });
  }

  Future<void> fetchTemplateCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _totalTemplates = 0;
        notifyListeners();
        return;
      }
      final response = await _templateRepo.fetchExistingTemplates(userId);
      _totalTemplates = response.length;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching templates count: $e");
    }
  }

  Future<void> fetchTemplates() async {
    isLoading = true;
    notifyListeners();
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        templates = await _templateRepo.fetchUserInstitutes(userId);
      }
    } catch (e) {
      debugPrint("Error fetching templates: $e");
    }
    isLoading = false;
    notifyListeners();
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
        templates.removeWhere((template) => template['id'].toString() == id.toString());
        _totalTemplates = templates.length;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("CRITICAL Delete Institute Error: $e");
      return false;
    }
  }
}