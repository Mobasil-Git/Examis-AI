import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveRepository {
  final String folderName = "Examis AI";

  Future<drive.DriveApi?> _getDriveApi() async {
    final session = Supabase.instance.client.auth.currentSession;
    final providerToken = session?.providerToken;

    if (providerToken == null) {
      throw Exception("No Google Provider Token found. User must log in with Google.");
    }

    final authHeaders = {
      'Authorization': 'Bearer $providerToken',
      'X-Goog-AuthUser': '0',
    };

    final client = GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  Future<String?> _getOrCreateFolder(drive.DriveApi driveApi) async {
    final folderQuery = await driveApi.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$folderName' and trashed=false",
      spaces: 'drive',
    );

    if (folderQuery.files != null && folderQuery.files!.isNotEmpty) {
      return folderQuery.files!.first.id;
    }

    final newFolder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(newFolder);
    return createdFolder.id;
  }

  Future<bool> backupFileToDrive({
    required String fileName,
    required String fileContent,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final folderId = await _getOrCreateFolder(driveApi);
      if (folderId == null) return false;

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final bytes = utf8.encode(fileContent);
      final media = drive.Media(Stream.value(bytes), bytes.length);

      await driveApi.files.create(driveFile, uploadMedia: media);
      return true;
    } catch (e) {
      throw Exception("Google Drive Upload Error: $e");
    }
  }
}