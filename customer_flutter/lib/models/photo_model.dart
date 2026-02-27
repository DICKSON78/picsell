import 'package:cloud_firestore/cloud_firestore.dart';

enum PhotoStatus { processing, completed, failed }

class PhotoModel {
  final String id;
  final String userId;
  final String originalUrl;
  final String? processedUrl;
  final PhotoStatus status;
  final bool downloaded;
  final int creditsUsed;
  final DateTime createdAt;

  PhotoModel({
    required this.id,
    required this.userId,
    required this.originalUrl,
    this.processedUrl,
    this.status = PhotoStatus.processing,
    this.downloaded = false,
    this.creditsUsed = 1,
    required this.createdAt,
  });

  factory PhotoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      originalUrl: data['originalUrl'] ?? '',
      processedUrl: data['processedUrl'],
      status: _parseStatus(data['status']),
      downloaded: data['downloaded'] ?? false,
      creditsUsed: data['creditsUsed'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static PhotoStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return PhotoStatus.completed;
      case 'failed':
        return PhotoStatus.failed;
      default:
        return PhotoStatus.processing;
    }
  }

  String get statusString {
    switch (status) {
      case PhotoStatus.completed:
        return 'completed';
      case PhotoStatus.failed:
        return 'failed';
      case PhotoStatus.processing:
        return 'processing';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originalUrl': originalUrl,
      'processedUrl': processedUrl,
      'status': statusString,
      'downloaded': downloaded,
      'creditsUsed': creditsUsed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PhotoModel copyWith({
    String? id,
    String? userId,
    String? originalUrl,
    String? processedUrl,
    PhotoStatus? status,
    bool? downloaded,
    int? creditsUsed,
    DateTime? createdAt,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalUrl: originalUrl ?? this.originalUrl,
      processedUrl: processedUrl ?? this.processedUrl,
      status: status ?? this.status,
      downloaded: downloaded ?? this.downloaded,
      creditsUsed: creditsUsed ?? this.creditsUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
