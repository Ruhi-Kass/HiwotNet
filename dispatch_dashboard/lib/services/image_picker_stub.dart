/// Fallback stub for [ImagePickerService] when running in non-web environments (such as VM unit tests).
class ImagePickerService {
  static void pickImage(void Function(String base64DataUrl) onPicked) {}
}
