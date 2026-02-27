import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String name;
  final int credits;
  final int price;
  final bool isActive;
  final String? discount;
  final bool isPopular;
  final int sales;

  PackageModel({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    this.isActive = true,
    this.discount,
    this.isPopular = false,
    this.sales = 0,
  });

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: data['name'] ?? '',
      credits: data['credits'] ?? 0,
      price: data['price'] ?? 0,
      isActive: data['isActive'] ?? true,
      discount: data['discount'],
      isPopular: data['isPopular'] ?? false,
      sales: data['sales'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'credits': credits,
      'price': price,
      'isActive': isActive,
      'discount': discount,
      'isPopular': isPopular,
      'sales': sales,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String userId; // 'all' or specific userId
  final String type; // 'info', 'promo', 'alert'
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    this.type = 'info',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      userId: data['userId'] ?? 'all',
      type: data['type'] ?? 'info',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'userId': userId,
      'type': type,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
