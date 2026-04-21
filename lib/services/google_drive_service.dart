import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. We need a custom HTTP client that injects the Google Auth Token into every request
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  final String folderName = "Examis AI";

  // Helper to get the authenticated Drive API client using Supabase's stored Google token
  Future<drive.DriveApi?> _getDriveApi() async {
    final session = Supabase.instance.client.auth.currentSession;
    final providerToken = session?.providerToken;

    if (providerToken == null) {
      debugPrint(
        "No Google Provider Token found. User must log in with Google.",
      );
      return null;
    }

    final authHeaders = {
      'Authorization': 'Bearer $providerToken',
      'X-Goog-AuthUser': '0',
    };

    final client = GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  // --- Core Function: Find or Create the Folder ---
  Future<String?> _getOrCreateFolder(drive.DriveApi driveApi) async {
    try {
      // 1. Search for the folder by name
      final folderQuery = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false",
        spaces: 'drive',
      );

      if (folderQuery.files != null && folderQuery.files!.isNotEmpty) {
        debugPrint("Found existing folder!");
        return folderQuery.files!.first.id; // Return existing folder ID
      }

      // 2. If not found, create it!
      debugPrint("Folder not found. Creating new '$folderName' folder...");
      final newFolder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(newFolder);
      return createdFolder.id;
    } catch (e) {
      debugPrint("Error finding/creating folder: $e");
      return null;
    }
  }

  // --- Main Action: Upload a File ---
  Future<bool> backupFileToDrive({
    required String fileName,
    required String fileContent,
    // In the future, this could be a File object if uploading PDFs/Docs
  }) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return false;

    final folderId = await _getOrCreateFolder(driveApi);
    if (folderId == null) return false;

    try {
      // 1. Prepare the file metadata (Name and where to put it)
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId]; // Put it inside our Examis AI folder!

      // 2. Prepare the actual content (Converting string to bytes for upload)
      final bytes = utf8.encode(fileContent);
      final media = drive.Media(Stream.value(bytes), bytes.length);

      // 3. Upload it!
      await driveApi.files.create(driveFile, uploadMedia: media);
      debugPrint("Backup successful!");
      return true;
    } catch (e) {
      debugPrint("Error uploading file: $e");
      return false;
    }
  }
}
