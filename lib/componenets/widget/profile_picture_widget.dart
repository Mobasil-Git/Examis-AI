import 'package:examis_ai/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String userId;
  final String? initialAvatarUrl;

  // 🚀 NEW: Added radius and badge toggle to make it truly universal!
  final double radius;
  final bool showEditBadge;

  const ProfilePictureWidget({
    super.key,
    required this.userId,
    this.initialAvatarUrl,
    this.radius = 60.0, // Defaults to 120x120 so your Edit Profile page stays the same
    this.showEditBadge = true, // Defaults to showing the camera
  });

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
  @override
  void didUpdateWidget(covariant ProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAvatarUrl != oldWidget.initialAvatarUrl) {
      setState(() {
        _currentAvatarUrl = widget.initialAvatarUrl;
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    setState(() => _isUploading = true);

    final newUrl = await ImageService().pickCropCompressAndUpload(context, widget.userId);

    if (newUrl != null) {
      setState(() {
        _currentAvatarUrl = "$newUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      });
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total size based on radius
    final double size = widget.radius * 2;

    return GestureDetector(
      onTap: _isUploading ? null : _updateProfilePicture,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Container(
              width: size,
              height: size,
              color: Colors.white.withAlpha(32), // Adapted to look good on dark headers too
              child: _currentAvatarUrl == null
                  ? Icon(Icons.person, size: widget.radius, color: Colors.white)
                  : CachedNetworkImage(
                imageUrl: _currentAvatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Padding(
                  padding: EdgeInsets.all(widget.radius / 2),
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.broken_image,
                  color: Colors.redAccent,
                  size: widget.radius / 1.5,
                ),
              ),
            ),
          ),

          // 🚀 THE EDIT ICON BADGE (Only shows if requested)
          if (widget.showEditBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(widget.radius * 0.15),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: widget.radius * 0.35),
              ),
            ),

          // Uploading Spinner Overlay
          if (_isUploading)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: SizedBox(
                  width: widget.radius * 0.8,
                  height: widget.radius * 0.8,
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}