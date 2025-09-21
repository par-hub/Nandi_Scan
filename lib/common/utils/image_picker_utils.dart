import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Utility class to handle image selection with cross-platform support
class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera or gallery
  static Future<Map<String, dynamic>?> pickImage({
    required ImageSource source,
    double maxWidth = 1024,
    double maxHeight = 1024,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          return {
            'webFile': pickedFile,
            'file': null,
            'hasImage': true,
          };
        } else {
          return {
            'webFile': null,
            'file': File(pickedFile.path),
            'hasImage': true,
          };
        }
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Clear image data
  static Map<String, dynamic> clearImage() {
    return {
      'webFile': null,
      'file': null,
      'hasImage': false,
    };
  }

  /// Check if image data contains a valid image
  static bool hasValidImage(Map<String, dynamic>? imageData) {
    if (imageData == null) return false;
    return imageData['hasImage'] == true &&
        (imageData['file'] != null || imageData['webFile'] != null);
  }
}