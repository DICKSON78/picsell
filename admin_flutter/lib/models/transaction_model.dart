import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { purchase, usage, bonus }

class TransactionModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final TransactionType type;
  final int credits;
  final double? amount;
  final String? paymentMethod;
  final String? description;
  final String status;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.type,
    required this.credits,
    this.amount,
    this.paymentMethod,
    this.description,
    this.status = 'completed',
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString(),
      userEmail: data['userEmail']?.toString(),
      type: _parseType(data['type']?.toString()),
      credits: (data['credits'] as num?)?.toInt() ?? 0,
      amount: (data['amount'] as num?)?.toDouble(),
      paymentMethod: data['paymentMethod']?.toString(),
      description: data['description']?.toString(),
      status: data['status']?.toString() ?? 'completed',
      createdAt: _parseDate(data['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static TransactionType _parseType(String? type) {
    switch (type) {
      case 'purchase':
        return TransactionType.purchase;
      case 'usage':
        return TransactionType.usage;
      case 'bonus':
        return TransactionType.bonus;
      default:
        return TransactionType.usage;
    }
  }

  String get typeString {
    switch (type) {
      case TransactionType.purchase:
        return 'purchase';
      case TransactionType.usage:
        return 'usage';
      case TransactionType.bonus:
        return 'bonus';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.purchase:
        return 'Ununuzi';
      case TransactionType.usage:
        return 'Matumizi';
      case TransactionType.bonus:
        return 'Bonus';
    }
  }
}
