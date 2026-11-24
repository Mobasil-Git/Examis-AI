import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repository/image_repository.dart';
import '../../utils/theme/app_colors.dart';
import '../../utils/utils.dart';
import '../../view_models/auth_provider.dart';

class ProfilePictureWidget extends ConsumerStatefulWidget {
  final String userId;
  final String? initialAvatarUrl;
  final double radius;
  final bool showEditBadge;

  const ProfilePictureWidget({
    super.key,
    required this.userId,
    this.initialAvatarUrl,
    this.radius = 60.0,
    this.showEditBadge = true,
  });

  @override
  ConsumerState<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends ConsumerState<ProfilePictureWidget> {
  bool _isUploading = false;
  String? _currentAvatarUrl;
  final ImageRepository _imageRepo = ImageRepository();

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

    try {
      await _imageRepo.pickCropCompressAndUpload(widget.userId);

      if (mounted) {
        await ref.read(authProvider.notifier).fetchUserProfile();
      }
    } catch (e) {
      if (mounted) {
        Utils.showSnackBar(context, e.toString(), AppColors.error);
      }
    }

    if (mounted) {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withAlpha(32),
              child: _currentAvatarUrl == null
                  ? Icon(Icons.person, size: widget.radius, color: Colors.white)
                  : CachedNetworkImage(
                imageUrl: _currentAvatarUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Padding(
                  padding: EdgeInsets.all(widget.radius / 2),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.broken_image,
                  color: AppColors.error,
                  size: widget.radius / 1.5,
                ),
              ),
            ),
          ),
          if (widget.showEditBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(widget.radius * 0.15),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: widget.radius * 0.35,
                ),
              ),
            ),
          if (_isUploading)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(150),
              ),
              child: Center(
                child: SizedBox(
                  width: widget.radius * 0.8,
                  height: widget.radius * 0.8,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}