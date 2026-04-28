import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  Future<String?> pickCropCompressAndUpload(
    BuildContext context,
    String userId,
  ) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return null;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        // Perfect square
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
      if (croppedFile == null) return null;

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            croppedFile.path,
            targetPath,
            quality: 70,
            minWidth: 400,
            minHeight: 400,
          );
      if (compressedFile == null) return null;

      final File finalImage = File(compressedFile.path);
      final String storagePath = '$userId/profile.jpg';

      await _supabase.storage
          .from('avatars')
          .upload(
            storagePath,
            finalImage,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      final String publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
      return null;
    }
  }
}
