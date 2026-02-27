import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? photoUrl;
  final int credits;
  final double totalSpent;
  final int totalPhotosProcessed;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  CustomerModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone = '',
    this.photoUrl,
    this.credits = 0,
    this.totalSpent = 0,
    this.totalPhotosProcessed = 0,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString(),
      credits: (data['credits'] as num?)?.toInt() ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalPhotosProcessed: (data['totalPhotosProcessed'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
      createdAt: _parseDate(data['createdAt']),
      lastLogin: _parseDate(data['lastLogin']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'credits': credits,
      'totalSpent': totalSpent,
      'totalPhotosProcessed': totalPhotosProcessed,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

  CustomerModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    int? credits,
    double? totalSpent,
    int? totalPhotosProcessed,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      credits: credits ?? this.credits,
      totalSpent: totalSpent ?? this.totalSpent,
      totalPhotosProcessed: totalPhotosProcessed ?? this.totalPhotosProcessed,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
