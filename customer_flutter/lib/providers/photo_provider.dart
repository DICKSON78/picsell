import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/photo_model.dart';
import '../services/firestore_service.dart';
import '../services/photoroom_service.dart';
import '../models/category_config.dart';

class PhotoProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final PhotoRoomService _photoRoomService = PhotoRoomService();

  List<PhotoModel> _photos = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  PhotoModel? _currentPhoto;

  List<PhotoModel> get photos => _photos;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  PhotoModel? get currentPhoto => _currentPhoto;

  // Load user's photo history
  Future<void> loadPhotos(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _photos = await _firestoreService.getPhotoHistory(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Process a new photo and save locally
  Future<PhotoModel?> processPhoto({
    required File imageFile,
    required String userId,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Process image with products category and save locally
      final result = await _photoRoomService.processByMode(imageFile, ProcessingMode.products);
      final processedFile = result.processedFile;

      // Create photo record with local path
      final photoId = await _firestoreService.createPhoto(
        userId: userId,
        originalUrl: imageFile.path, // Store local path
      );

      // Update photo record with processed local path
      await _firestoreService.updatePhotoProcessed(photoId, processedFile.path);

      // Create photo model with local paths
      _currentPhoto = PhotoModel(
        id: photoId,
        userId: userId,
        originalUrl: imageFile.path,
        processedUrl: processedFile.path,
        status: PhotoStatus.completed,
        createdAt: DateTime.now(),
      );

      // Add to local list
      _photos.insert(0, _currentPhoto!);

      _isProcessing = false;
      notifyListeners();
      return _currentPhoto;
    } catch (e) {
      _error = e.toString();
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }

  // Mark photo as downloaded
  Future<void> markDownloaded(String photoId) async {
    try {
      await _firestoreService.markPhotoDownloaded(photoId);
      // Update local list
      final index = _photos.indexWhere((p) => p.id == photoId);
      if (index != -1) {
        _photos[index] = _photos[index].copyWith(downloaded: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear current photo
  void clearCurrentPhoto() {
    _currentPhoto = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
