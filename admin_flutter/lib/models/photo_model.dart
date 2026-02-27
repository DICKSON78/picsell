import 'package:cloud_firestore/cloud_firestore.dart';

enum PhotoStatus { processing, completed, failed, flagged }

class PhotoModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String originalUrl;
  final String? processedUrl;
  final PhotoStatus status;
  final bool downloaded;
  final int creditsUsed;
  final String category;
  final DateTime createdAt;

  PhotoModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.originalUrl,
    this.processedUrl,
    this.status = PhotoStatus.processing,
    this.downloaded = false,
    this.creditsUsed = 1,
    this.category = 'Portrait',
    required this.createdAt,
  });

  factory PhotoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PhotoModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString(),
      userEmail: data['userEmail']?.toString(),
      originalUrl: data['originalUrl']?.toString() ?? '',
      processedUrl: data['processedUrl']?.toString(),
      status: _parseStatus(data['status']?.toString()),
      downloaded: data['downloaded'] == true,
      creditsUsed: (data['creditsUsed'] as num?)?.toInt() ?? 1,
      category: data['category']?.toString() ?? 'Portrait',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static PhotoStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
      case 'processed':
        return PhotoStatus.completed;
      case 'failed':
        return PhotoStatus.failed;
      case 'flagged':
        return PhotoStatus.flagged;
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
      case PhotoStatus.flagged:
        return 'flagged';
      case PhotoStatus.processing:
        return 'processing';
    }
  }

  PhotoModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? originalUrl,
    String? processedUrl,
    PhotoStatus? status,
    bool? downloaded,
    int? creditsUsed,
    String? category,
    DateTime? createdAt,
  }) {
    return PhotoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      originalUrl: originalUrl ?? this.originalUrl,
      processedUrl: processedUrl ?? this.processedUrl,
      status: status ?? this.status,
      downloaded: downloaded ?? this.downloaded,
      creditsUsed: creditsUsed ?? this.creditsUsed,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
