import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Upload image file to Firebase Storage
  /// Returns the download URL
  Future<String?> uploadImage(File file, String userId, {String folder = 'photos'}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final destination = 'users/$userId/$folder/$fileName';

      final ref = _storage.ref(destination);
      final task = await ref.putFile(file);
      
      if (task.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      // Upload failed
      return null;
    }
  }

  /// Upload processed image (bytes or file)
  Future<String?> uploadProcessedImage(File file, String userId) async {
    return uploadImage(file, userId, folder: 'processed');
  }

  /// Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Delete failed
    }
  }
}
