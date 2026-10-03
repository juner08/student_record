import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/picture_service.dart';

/// Draws the picture stored on a student.
///
/// The stored value can be an `http(s)` link or an uploaded `data:` image, so
/// both are resolved here. The image is always clipped to a circle and painted
/// with `BoxFit.cover`, which keeps a non-square photo from being stretched.
///
/// Anything missing or broken simply shows [fallback], so a bad path can never
/// take the student page down.
class StudentPicture extends StatelessWidget {
  const StudentPicture({
    super.key,
    required this.pictureUrl,
    required this.size,
    this.fallback,
    this.circular = true,
  });

  final String pictureUrl;
  final double size;
  final Widget? fallback;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final Widget content = SizedBox(
      width: size,
      height: size,
      child: _image(context) ?? (fallback ?? const SizedBox.shrink()),
    );
    if (!circular) return content;
    return ClipOval(
      child: SizedBox(width: size, height: size, child: content),
    );
  }

  Widget? _image(BuildContext context) {
    final String value = pictureUrl.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('data:')) {
      final Uint8List? bytes = PictureService.decode(value);
      if (bytes == null) return null;
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            fallback ?? const SizedBox.shrink(),
      );
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            fallback ?? const SizedBox.shrink(),
        loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
        ) =>
            progress == null
                ? child
                : (fallback ?? const SizedBox.shrink()),
      );
    }

    // Unsupported value (a local file path, for example). Never throws.
    return null;
  }
}
