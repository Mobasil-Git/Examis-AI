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

  Future<String> createInstituteProfile(String instituteName, File file) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return "User must be logged in.";

      final String originalFileName = file.path
          .split(RegExp(r'[/\\]'))
          .last
          .replaceAll(RegExp(r'\s+'), '_');

      final existingTemplates = await _supabase
          .from('institutes')
          .select('institute_name, template_url')
          .eq('user_id', user.id);

      // 3. The Double-Check Loop
      for (var template in existingTemplates) {

        // Check A: Did they type the exact same Institute Name?
        if (template['institute_name'].toString().trim().toLowerCase() == instituteName.trim().toLowerCase()) {
          return "An institute with the name '${instituteName.trim()}' already exists.";
        }

        // Check B: Did they select a file with the exact same name?
        if (template['template_url'].toString().contains(originalFileName)) {
          return "You have already uploaded a file named '$originalFileName'. Please rename it or choose a different one.";
        }
      }

      // 4. Upload with the ORIGINAL file name attached so our check works in the future!
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = '${user.id}_${timestamp}_$originalFileName';

      await _supabase.storage
          .from('templates')
          .upload(storageFileName, file, fileOptions: const FileOptions(upsert: true));

      final publicUrl = _supabase.storage.from('templates').getPublicUrl(storageFileName);

      // 5. Insert the new row
      await _supabase.from('institutes').insert({
        'user_id': user.id,
        'institute_name': instituteName.trim(),
        'template_url': publicUrl,
      });

      return "success";
    } catch (e) {
      print("Institute Creation Error: $e");
      return "An error occurred while uploading. Please try again.";
    }
  }
  Future<List<Map<String, dynamic>>> fetchUserInstitutes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

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

  // 🚀 CHANGED: Accepts `dynamic` so we don't accidentally cast Ints to Strings!
  Future<bool> deleteInstitute(dynamic id) async {
    try {
      final response = await _supabase
          .from('institutes')
          .select('template_url')
          .eq('id', id)
          .single();

      final String? templateUrl = response['template_url'];

      if (templateUrl != null && templateUrl.isNotEmpty) {
        Uri uri = Uri.parse(templateUrl);
        String fileName = uri.pathSegments.last;
        await _supabase.storage.from('templates').remove([fileName]);
      }

      // 🚀 ADDED .select() at the end to ensure it ACTUALLY deleted something!
      final deletedRow = await _supabase.from('institutes').delete().eq('id', id).select();

      if (deletedRow.isEmpty) {
        print("WARNING: No row was deleted. Check your RLS DELETE policies!");
        return false;
      }

      return true;
    } catch (e) {
      print("CRITICAL Delete Institute Error: $e");
      return false;
    }
  }
}