import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../services/firestore_service.dart';

class PhotosProvider with ChangeNotifier {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  List<PhotoModel> _photos = [];
  bool _isLoading = false;
  String? _error;

  List<PhotoModel> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPhotos({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _photos = await _firestoreService.getPhotos(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePhoto(String photoId) async {
    try {
      await _firestoreService.deletePhoto(photoId);
      _photos.removeWhere((p) => p.id == photoId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> flagPhoto(String photoId, bool isFlagged) async {
    try {
       await _firestoreService.updatePhotoStatus(photoId, isFlagged ? 'flagged' : 'processed');
       final index = _photos.indexWhere((p) => p.id == photoId);
       if (index != -1) {
         _photos[index] = _photos[index].copyWith(status: isFlagged ? PhotoStatus.flagged : PhotoStatus.completed);
         notifyListeners();
       }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
