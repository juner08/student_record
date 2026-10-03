import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Outcome of a "choose a picture" action.
class PicturePickResult {
  const PicturePickResult.picked(this.value) : error = null;

  const PicturePickResult.cancelled()
      : value = null,
        error = null;

  const PicturePickResult.failed(this.error) : value = null;

  /// The picture stored on the student: an `http(s)` link or a data URI.
  final String? value;

  /// User readable reason why the picture could not be used.
  final String? error;

  bool get isCancelled => value == null && error == null;
}

/// Reads an image from the device and turns it into a value that can be saved
/// with the student.
///
/// The picked bytes are decoded, scaled down and re-encoded as PNG, then stored
/// as a `data:` URI. That keeps a single storage field working on every
/// platform: a plain file path is meaningless in the browser and would render
/// as a broken image after a refresh.
class PictureService {
  PictureService._();

  static final PictureService instance = PictureService._();

  /// Longest edge kept for a stored picture, in pixels.
  static const int maxEdge = 192;

  /// Refuse anything that is still unreasonably large after scaling.
  static const int maxBytes = 2 * 1024 * 1024;

  static const String dataUriPrefix = 'data:image/png;base64,';

  final ImagePicker _picker = ImagePicker();

  /// The camera button only makes sense on devices that have a camera.
  static bool get hasCamera {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Opens the gallery / camera and returns the value to store.
  Future<PicturePickResult> pick(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 92,
      );
      if (file == null) return const PicturePickResult.cancelled();
      return encode(await file.readAsBytes());
    } catch (error) {
      debugPrint('PictureService: picker failed ($error)');
      return const PicturePickResult.failed(
        'Could not open the image picker. Please choose the picture again.',
      );
    }
  }

  /// Normalises raw image bytes into a storable value.
  Future<PicturePickResult> encode(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return const PicturePickResult.failed('That file is not a valid image.');
    }
    final Uint8List? png = await _toSmallPng(bytes);
    // The resized bytes are always PNG. If the decoder was unavailable the
    // original bytes are kept and labelled from their magic numbers - data we
    // cannot recognise is refused instead of being stored as a broken image.
    final String? type = png != null ? 'png' : mimeOf(bytes);
    if (type == null) {
      return const PicturePickResult.failed('That file is not a valid image.');
    }
    final Uint8List data = png ?? bytes;
    if (data.lengthInBytes > maxBytes) {
      return const PicturePickResult.failed(
        'That image is too large. Please choose a smaller photo.',
      );
    }
    return PicturePickResult.picked(
      'data:image/$type;base64,${base64Encode(data)}',
    );
  }

  /// Reads the image type from the leading bytes, or null when unknown.
  static String? mimeOf(Uint8List bytes) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (int i = 0; i < signature.length; i++) {
        if (bytes[i] != signature[i]) return false;
      }
      return true;
    }

    if (startsWith(<int>[0x89, 0x50, 0x4E, 0x47])) return 'png';
    if (startsWith(<int>[0xFF, 0xD8, 0xFF])) return 'jpeg';
    if (startsWith(<int>[0x47, 0x49, 0x46])) return 'gif';
    if (startsWith(<int>[0x42, 0x4D])) return 'bmp';
    if (startsWith(<int>[0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    return null;
  }

  /// Decodes and scales the image down. Returns null when the platform decoder
  /// cannot read the file, so the original bytes are still used.
  Future<Uint8List?> _toSmallPng(Uint8List bytes) async {
    ui.Codec? probe;
    ui.Codec? codec;
    ui.FrameInfo? frame;
    try {
      probe = await ui.instantiateImageCodec(bytes);
      frame = await probe.getNextFrame();
      final int width = frame.image.width;
      final int height = frame.image.height;
      final int longest = width > height ? width : height;
      final double scale =
          longest > maxEdge ? maxEdge / longest.toDouble() : 1.0;

      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: (width * scale).round().clamp(1, maxEdge),
        targetHeight: (height * scale).round().clamp(1, maxEdge),
        allowUpscaling: false,
      );
      final ui.FrameInfo scaled = await codec.getNextFrame();
      final ByteData? encoded =
          await scaled.image.toByteData(format: ui.ImageByteFormat.png);
      scaled.image.dispose();
      return encoded?.buffer.asUint8List();
    } catch (error) {
      debugPrint('PictureService: image could not be resized ($error)');
      return null;
    } finally {
      frame?.image.dispose();
      probe?.dispose();
      codec?.dispose();
    }
  }

  /// True when [value] already holds an uploaded picture.
  static bool isUploaded(String value) => value.trim().startsWith('data:');

  /// True when [value] can be shown as a picture.
  static bool isDisplayable(String value) {
    final String text = value.trim();
    if (text.isEmpty) return false;
    if (text.startsWith('data:')) return decode(text) != null;
    return text.startsWith('http://') || text.startsWith('https://');
  }

  /// Reads the bytes of a `data:` URI. Returns null for anything malformed so
  /// a broken value never throws in the widget tree.
  static Uint8List? decode(String value) {
    final String text = value.trim();
    if (!text.startsWith('data:')) return null;
    final int comma = text.indexOf(',');
    if (comma == -1 || comma + 1 >= text.length) return null;
    final String header = text.substring(5, comma);
    if (!header.contains('base64')) return null;
    try {
      final Uint8List bytes = base64Decode(
        text.substring(comma + 1).replaceAll(RegExp(r'\s'), ''),
      );
      return bytes.isEmpty ? null : bytes;
    } catch (error) {
      debugPrint('PictureService: broken data URI ($error)');
      return null;
    }
  }
}
