import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { purchase, usage, bonus }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final int credits;
  final double? amount;
  final String? paymentMethod;
  final String? description;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.credits,
    this.amount,
    this.paymentMethod,
    this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseType(data['type']),
      credits: data['credits'] ?? 0,
      amount: (data['amount'] as num?)?.toDouble(),
      paymentMethod: data['paymentMethod'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
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

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': typeString,
      'credits': credits,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
