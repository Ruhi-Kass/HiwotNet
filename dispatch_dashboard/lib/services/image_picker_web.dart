// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Browser-native implementation of [ImagePickerService] for Flutter Web.
///
/// Uses the browser's DOM FileUploadInputElement and FileReader APIs to let operators
/// upload their official profile/badge photos directly from disk without external packages.
/// Converts the selected image into a Base64 Data URL for instant in-memory rendering
/// and localStorage persistence.
class ImagePickerService {
  static void pickImage(void Function(String base64DataUrl) onPicked) {
    try {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();
      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            final result = reader.result;
            if (result is String) {
              onPicked(result);
            }
          });
        }
      });
    } catch (_) {}
  }
}
