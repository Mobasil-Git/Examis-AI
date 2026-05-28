import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/template_service.dart';

class TemplateProvider extends ChangeNotifier {
  int _totalTemplates = 0;
  final TemplateService _service = TemplateService();
  List<Map<String, dynamic>> templates = [];
  bool isLoading = false;
  int get totalTemplates => _totalTemplates;

  TemplateProvider() {
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

      final response = await Supabase.instance.client
          .from('institutes')
          .select('id')
          .eq('user_id', userId);

      _totalTemplates = response.length;
      notifyListeners();
    } catch (e) {
      print("Error fetching templates count: $e");
    }
  }
  Future<void> fetchTemplates() async {
    isLoading = true;
    notifyListeners();

    templates = await _service.fetchUserInstitutes();

    isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteTemplate(dynamic id) async {
    bool success = await _service.deleteInstitute(id);

    if (success) {
      // Compare them safely
      templates.removeWhere((template) => template['id'].toString() == id.toString());
      _totalTemplates = templates.length;
      notifyListeners();
      return true;
    }
    return false;
  }
}