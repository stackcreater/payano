import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class AppUploadedFile {
  final String name;
  final String extension;
  final int size;
  final Uint8List? bytes;

  AppUploadedFile({
    required this.name,
    required this.extension,
    required this.size,
    this.bytes,
  });

  String get formattedSize {
    if (size <= 0) return '';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage {
    final lower = extension.toLowerCase();
    return lower == 'png' || lower == 'jpg' || lower == 'jpeg' || lower == 'webp';
  }

  static Future<AppUploadedFile?> pickDocument() async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
      );
      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        final size = await file.length();
        final ext = file.name.contains('.') ? file.name.split('.').last.toUpperCase() : 'DOC';
        return AppUploadedFile(
          name: file.name,
          extension: ext,
          size: size,
          bytes: bytes,
        );
      }
    } catch (_) {}
    return null;
  }
}
