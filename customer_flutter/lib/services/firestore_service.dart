import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/photo_model.dart';
import '../models/transaction_model.dart';
import '../models/shared_models.dart';

class FirestoreService {
  // Lazy initialization to avoid accessing Firebase before it's ready
  FirebaseFirestore? _firestoreInstance;

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // ============================================
  // USER OPERATIONS
  // ============================================

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user data (for compatibility)
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user data (for phone number saving)
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Stream user data (realtime updates)
  Stream<UserModel?> streamUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user credits
  Future<void> updateCredits(String userId, int newCredits) async {
    await _firestore.collection('users').doc(userId).update({
      'credits': newCredits,
    });
  }

  // Deduct credit
  Future<bool> deductCredit(String userId, {int amount = 1}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final currentCredits = userDoc.data()?['credits'] ?? 0;
      if (currentCredits < amount) return false;

      await _firestore.collection('users').doc(userId).update({
        'credits': currentCredits - amount,
      });

      // Log transaction
      await _firestore.collection('transactions').add({
        'userId': userId,
        'type': 'usage',
        'credits': -amount,
        'description': 'Photo processing',
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Add credits
  Future<void> addCredits(String userId, int amount, {String? description, double? payment}) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final currentCredits = userDoc.data()?['credits'] ?? 0;
    final totalSpent = (userDoc.data()?['totalSpent'] ?? 0).toDouble();

    await _firestore.collection('users').doc(userId).update({
      'credits': currentCredits + amount,
      'totalSpent': totalSpent + (payment ?? 0),
    });

    // Log transaction
    await _firestore.collection('transactions').add({
      'userId': userId,
      'type': 'purchase',
      'credits': amount,
      'amount': payment,
      'description': description ?? 'Credit purchase',
      'createdAt': Timestamp.now(),
    });
  }

  // ============================================
  // PHOTO OPERATIONS
  // ============================================

  // Create photo record
  Future<String> createPhoto({
    required String userId,
    required String originalUrl,
  }) async {
    final docRef = await _firestore.collection('photos').add({
      'userId': userId,
      'originalUrl': originalUrl,
      'processedUrl': null,
      'status': 'processing',
      'downloaded': false,
      'creditsUsed': 1,
      'createdAt': Timestamp.now(),
    });
    return docRef.id;
  }

  // Update photo with processed URL
  Future<void> updatePhotoProcessed(String photoId, String processedUrl) async {
    await _firestore.collection('photos').doc(photoId).update({
      'processedUrl': processedUrl,
      'status': 'completed',
    });
  }

  // Mark photo as failed
  Future<void> markPhotoFailed(String photoId) async {
    await _firestore.collection('photos').doc(photoId).update({
      'status': 'failed',
    });
  }

  // Mark photo as downloaded
  Future<void> markPhotoDownloaded(String photoId) async {
    await _firestore.collection('photos').doc(photoId).update({
      'downloaded': true,
    });
  }

  // Get user's photo history
  Future<List<PhotoModel>> getPhotoHistory(String userId, {int limit = 50}) async {
    final query = await _firestore
        .collection('photos')
        .where('userId', isEqualTo: userId)
        .get();

    final photos = query.docs.map((doc) => PhotoModel.fromFirestore(doc)).toList();
    // Sort client-side to avoid index requirement
    photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return photos.take(limit).toList();
  }

  // Stream user's photos (realtime)
  Stream<List<PhotoModel>> streamUserPhotos(String userId) {
    return _firestore
        .collection('photos')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final photos = snapshot.docs.map((doc) => PhotoModel.fromFirestore(doc)).toList();
          // Sort by date (newest first) client-side to avoid index requirement
          photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return photos;
        });
  }

  // ============================================
  // TRANSACTION OPERATIONS
  // ============================================

  // Get user's transaction history
  Future<List<TransactionModel>> getTransactionHistory(String userId, {int limit = 50}) async {
    final query = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = query.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    // Sort client-side to avoid index requirement
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transactions.take(limit).toList();
  }

  // Stream transactions (realtime)
  Stream<List<TransactionModel>> streamTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
          // Sort client-side to avoid index requirement
          transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return transactions;
        });
  }

  // ============================================
  // CREDIT PACKAGES
  // ============================================

  // Stream available credit packages from Firestore
  Stream<List<PackageModel>> streamPackages() {
    return _firestore
        .collection('packages')
        .snapshots()
        .map((snapshot) {
          final packages = snapshot.docs
              .map((doc) => PackageModel.fromFirestore(doc))
              .where((p) => p.isActive)
              .toList();
          packages.sort((a, b) => a.price.compareTo(b.price));
          return packages;
        });
  }

  // Get packages as a one-time fetch
  Future<List<PackageModel>> getPackages() async {
    try {
      final snapshot = await _firestore
          .collection('packages')
          .get();

      final packages = snapshot.docs
          .map((doc) => PackageModel.fromFirestore(doc))
          .where((p) => p.isActive)
          .toList();

      // Sort by price ascending
      packages.sort((a, b) => a.price.compareTo(b.price));

      return packages;
    } catch (e) {
      // getPackages error
      rethrow;
    }
  }

  // Update package sales count
  Future<void> updatePackageSales(String packageId) async {
    final packageRef = _firestore.collection('packages').doc(packageId);
    await _firestore.runTransaction((transaction) async {
      final packageDoc = await transaction.get(packageRef);
      if (packageDoc.exists) {
        final currentSales = packageDoc.data()?['sales'] ?? 0;
        transaction.update(packageRef, {'sales': currentSales + 1});
      }
    });
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  // Stream notifications for current user
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', whereIn: [userId, 'all'])
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
          // Sort by date (newest first) client-side to avoid index requirement
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', whereIn: [userId, 'all'])
        .where('isRead', isEqualTo: false)
        .get();
    
    return snapshot.docs.length;
  }

  // ============================================
  // PAYMENT METHODS
  // ============================================

  // Save payment method
  Future<void> savePaymentMethod(PaymentMethodModel method) async {
    if (method.isDefault) {
      // Unset other defaults for this user
      final defaults = await _firestore
          .collection('payment_methods')
          .where('userId', isEqualTo: method.userId)
          .where('isDefault', isEqualTo: true)
          .get();
      
      for (var doc in defaults.docs) {
        await doc.reference.update({'isDefault': false});
      }
    }

    await _firestore.collection('payment_methods').add(method.toFirestore());
  }

  // Stream user's payment methods
  Stream<List<PaymentMethodModel>> streamPaymentMethods(String userId) {
    return _firestore
        .collection('payment_methods')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentMethodModel.fromFirestore(doc)).toList());
  }

  // Set default payment method
  Future<void> setDefaultPaymentMethod(String userId, String methodId) async {
    // Unset current default
    final defaults = await _firestore
        .collection('payment_methods')
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: true)
        .get();
    
    for (var doc in defaults.docs) {
      await doc.reference.update({'isDefault': false});
    }

    // Set new default
    await _firestore.collection('payment_methods').doc(methodId).update({
      'isDefault': true,
    });
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String methodId) async {
    await _firestore.collection('payment_methods').doc(methodId).delete();
  }
}
