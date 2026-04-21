import 'package:examis_ai/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String userId;
  final String? initialAvatarUrl;

  const ProfilePictureWidget({super.key, required this.userId, this.initialAvatarUrl});

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  bool _isUploading = false;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.initialAvatarUrl;
  }

  Future<void> _updateProfilePicture() async {
    setState(() => _isUploading = true);

    final newUrl = await ImageService().pickCropCompressAndUpload(context, widget.userId);

    if (newUrl != null) {
      setState(() {
        // We append a timestamp so CachedNetworkImage knows the URL "changed" and fetches the new one!
        _currentAvatarUrl = "$newUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      });
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _updateProfilePicture,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Container(
              width: 120,
              height: 120,
              color: Colors.grey[300], // Fallback background
              child: _currentAvatarUrl == null
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : CachedNetworkImage(
                imageUrl: _currentAvatarUrl!,
                fit: BoxFit.cover,
                // Shows a tiny spinner while the image downloads from Supabase
                placeholder: (context, url) => const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                // Shows a red error icon if the link is broken
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ),
          ),

          // The Edit Icon Badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.blueAccent, // Use your primary color here
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),

          // Uploading Spinner Overlay
          if (_isUploading)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}