import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'admin',
    this.isActive = true,
    this.isApproved = false,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Admin',
      role: data['role']?.toString() ?? 'admin',
      isActive: data['isActive'] == true,
      isApproved: data['isApproved'] == true,
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
      'role': role,
      'isActive': isActive,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isPendingApproval => !isApproved && isActive;
}
