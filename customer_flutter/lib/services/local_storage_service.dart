import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static const String _appFolderName = 'PicSell_Photos';

  // Singleton pattern
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Get app's photo directory
  Future<Directory> _getPhotoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${appDir.path}/$_appFolderName');

    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    return photoDir;
  }

  // ── Caption helpers ──────────────────────────────────────────

  /// Derives the JSON sidecar path for a given image file.
  String _captionPath(File imageFile) =>
      imageFile.path.replaceAll(RegExp(r'\.(png|jpg|jpeg)$', caseSensitive: false), '.json');

  /// Persist caption fields alongside the image.
  Future<void> saveCaption(File imageFile, Map<String, String> caption) async {
    final jsonFile = File(_captionPath(imageFile));
    await jsonFile.writeAsString(jsonEncode(caption));
  }

  /// Load caption fields for an image. Returns empty map if none saved.
  Future<Map<String, String>> loadCaption(File imageFile) async {
    final jsonFile = File(_captionPath(imageFile));
    if (!await jsonFile.exists()) return {};
    try {
      final raw = jsonDecode(await jsonFile.readAsString());
      return Map<String, String>.from(raw as Map);
    } catch (_) {
      return {};
    }
  }

  // ── Image storage ────────────────────────────────────────────

  // Save processed image to local storage
  Future<File> saveProcessedImage(Uint8List imageBytes, {String? customName}) async {
    final photoDir = await _getPhotoDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // .jpg — matches the JPEG format requested from PhotoRoom API
    final fileName = customName ?? 'processed_$timestamp.jpg';
    final file = File('${photoDir.path}/$fileName');

    await file.writeAsBytes(imageBytes);
    return file;
  }

  // Save original image copy to local storage
  Future<File> saveOriginalImage(File originalImage) async {
    final photoDir = await _getPhotoDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'original_$timestamp.jpg';
    final newFile = File('${photoDir.path}/$fileName');

    await originalImage.copy(newFile.path);
    return newFile;
  }

  // Get all processed images from local storage
  Future<List<File>> getProcessedImages() async {
    final photoDir = await _getPhotoDirectory();

    if (!await photoDir.exists()) {
      return [];
    }

    final files = await photoDir.list().toList();
    final imageFiles = files
        .whereType<File>()
        .where((file) {
          final p = file.path.toLowerCase();
          return p.contains('processed_') &&
              (p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.png'));
        })
        .toList();

    // Sort by modification date (newest first)
    imageFiles.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return bTime.compareTo(aTime);
    });

    return imageFiles;
  }

  // Get recent processed images (limited count)
  Future<List<File>> getRecentImages({int limit = 10}) async {
    final allImages = await getProcessedImages();
    return allImages.take(limit).toList();
  }

  // Delete a processed image and ALL associated files:
  //   • the image itself          (processed_xxx.jpg)
  //   • caption JSON sidecar      (processed_xxx.json)
  //   • clean-original backup     (processed_xxx.jpg.orig)
  Future<bool> deleteImage(File imageFile) async {
    try {
      if (await imageFile.exists()) {
        await imageFile.delete();
      } else {
        return false;
      }
      // Caption JSON sidecar
      final jsonFile = File(_captionPath(imageFile));
      if (await jsonFile.exists()) await jsonFile.delete();
      // Clean-original backup used for caption re-burns
      final origFile = File('${imageFile.path}.orig');
      if (await origFile.exists()) await origFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get total count of processed images
  Future<int> getImageCount() async {
    final images = await getProcessedImages();
    return images.length;
  }

  // Clear all processed images
  Future<void> clearAllImages() async {
    final photoDir = await _getPhotoDirectory();
    if (await photoDir.exists()) {
      await photoDir.delete(recursive: true);
      await photoDir.create(); // Recreate empty folder
    }
  }

  // Get image by filename
  Future<File?> getImageByName(String fileName) async {
    final photoDir = await _getPhotoDirectory();
    final file = File('${photoDir.path}/$fileName');

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  // Check if any images exist
  Future<bool> hasImages() async {
    final images = await getProcessedImages();
    return images.isNotEmpty;
  }

  // Get storage path for display
  Future<String> getStoragePath() async {
    final photoDir = await _getPhotoDirectory();
    return photoDir.path;
  }
}
