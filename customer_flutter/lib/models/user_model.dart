import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String? photoUrl;
  final int credits;
  final double totalSpent;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? phoneNumber;
  final bool? phoneVerified;
  final String? phoneUpdatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone = '',
    this.photoUrl,
    this.credits = 5,
    this.totalSpent = 0,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
    this.phoneNumber,
    this.phoneVerified,
    this.phoneUpdatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'],
      credits: data['credits'] ?? 5,
      totalSpent: (data['totalSpent'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      phoneNumber: data['phoneNumber'],
      phoneVerified: data['phoneVerified'],
      phoneUpdatedAt: data['phoneUpdatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'credits': credits,
      'totalSpent': totalSpent,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'phoneUpdatedAt': phoneUpdatedAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    int? credits,
    double? totalSpent,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      credits: credits ?? this.credits,
      totalSpent: totalSpent ?? this.totalSpent,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
