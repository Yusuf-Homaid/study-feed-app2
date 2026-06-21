import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../theme/app_theme.dart';

/// Full-screen image viewer with pinch-to-zoom / pan, opened when a
/// user taps an image inside a post card.
class LightboxScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const LightboxScreen({super.key, required this.imageBytes});

  static Route<void> route(Uint8List imageBytes) {
    return PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: LightboxScreen(imageBytes: imageBytes),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: Stack(
        children: [
          Positioned.fill(
            child: PhotoView(
              imageProvider: MemoryImage(imageBytes),
              backgroundDecoration: const BoxDecoration(color: AppColors.pureBlack),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              heroAttributes: const PhotoViewHeroAttributes(tag: 'lightbox-image'),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: _CloseButton(onTap: () => Navigator.of(context).pop()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.close, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
