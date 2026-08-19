import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageRepository {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  Future<String> pickCropCompressAndUpload(String userId) async {
    try {
      // 1. Pick Image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) throw Exception("Image selection cancelled.");

      // 2. Crop Image
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
          ),
        ],
      );
      if (croppedFile == null) throw Exception("Image cropping cancelled.");

      // 3. Compress Image
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        targetPath,
        quality: 70,
        minWidth: 400,
        minHeight: 400,
      );

      if (compressedFile == null) throw Exception("Image compression failed.");
      final File finalImage = File(compressedFile.path);

      // 4. Fetch the old avatar URL from the database
      final profileResponse = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();

      final String? oldAvatarUrl = profileResponse['avatar_url'];

      // 5. Delete the old image from the storage bucket
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        // Extract the specific file path from the public URL
        final parts = oldAvatarUrl.split('avatars/');
        if (parts.length > 1) {
          final String oldStoragePath = parts[1].split('?').first; // Remove query params if any
          await _supabase.storage.from('avatars').remove([oldStoragePath]);
        }
      }

      // 6. Upload new image with a UNIQUE timestamped filename
      final String uniqueFileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newStoragePath = '$userId/$uniqueFileName';

      await _supabase.storage.from('avatars').upload(
        newStoragePath,
        finalImage,
      );

      // 7. Get new public URL and update the profile table
      final String newPublicUrl = _supabase.storage.from('avatars').getPublicUrl(newStoragePath);

      await _supabase
          .from('profiles')
          .update({'avatar_url': newPublicUrl})
          .eq('id', userId);

      return newPublicUrl;
    } catch (e) {
      throw Exception("Error processing image: $e");
    }
  }
}