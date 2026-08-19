import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TemplateRepository {
  final _supabase = Supabase.instance.client;

  Future<File?> pickTemplateFile() async {
    List<PlatformFile>? files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );

    if (files.isNotEmpty && files.single.path != null) {
      return File(files.single.path!);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchExistingTemplates(String userId) async {
    final response = await _supabase
        .from('institutes')
        .select('institute_name, template_url')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> uploadTemplateFile(String storageFileName, File file) async {
    await _supabase.storage.from('templates').upload(
      storageFileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return _supabase.storage.from('templates').getPublicUrl(storageFileName);
  }

  Future<void> insertInstitute(String userId, String instituteName, String publicUrl) async {
    await _supabase.from('institutes').insert({
      'user_id': userId,
      'institute_name': instituteName,
      'template_url': publicUrl,
    });
  }

  Future<List<Map<String, dynamic>>> fetchUserInstitutes(String userId) async {
    final response = await _supabase
        .from('institutes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> fetchInstituteById(dynamic id) async {
    return await _supabase
        .from('institutes')
        .select('template_url')
        .eq('id', id)
        .single();
  }

  Future<void> deleteTemplateFile(String fileName) async {
    await _supabase.storage.from('templates').remove([fileName]);
  }

  Future<List<Map<String, dynamic>>> deleteInstituteRecord(dynamic id) async {
    final response = await _supabase
        .from('institutes')
        .delete()
        .eq('id', id)
        .select();
    return List<Map<String, dynamic>>.from(response);
  }
}