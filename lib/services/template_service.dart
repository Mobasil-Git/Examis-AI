import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TemplateService {
  final _supabase = Supabase.instance.client;

  Future<File?> pickTemplateFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
      );
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print("File Picker Error: $e");
      return null;
    }
  }

  Future<bool> createInstituteProfile(String instituteName, File file) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null)
        throw Exception("User must be logged in to create an institute.");

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = instituteName
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      final fileName = '${user.id}_${cleanName}_$timestamp.docx';

      await _supabase.storage
          .from('templates')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabase.storage
          .from('templates')
          .getPublicUrl(fileName);

      await _supabase.from('institutes').insert({
        'user_id': user.id,
        'institute_name': instituteName,
        'template_url': publicUrl,
      });

      return true;
    } catch (e) {
      print("Institute Creation Error: $e");
      return false;
    }
  }

  // --- Add this to TemplateService ---

  Future<List<Map<String, dynamic>>> fetchUserInstitutes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Fetch all templates for this user, newest first
      final response = await _supabase
          .from('institutes')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Fetch Institutes Error: $e");
      return [];
    }
  }

  Future<bool> deleteInstitute(int id) async {
    try {
      // Note: In a full app, you should also delete the file from the storage bucket here!
      await _supabase.from('institutes').delete().eq('id', id);
      return true;
    } catch (e) {
      print("Delete Institute Error: $e");
      return false;
    }
  }
}
