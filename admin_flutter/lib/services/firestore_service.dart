import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import '../models/admin_model.dart';
import '../models/photo_model.dart';
import '../models/transaction_model.dart';
import '../models/shared_models.dart';
import '../models/system_settings_model.dart';

class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AdminFirestoreService _instance = AdminFirestoreService._internal();
  factory AdminFirestoreService() => _instance;
  AdminFirestoreService._internal();

  // ============================================
  // DASHBOARD STATISTICS
  // ============================================

  Future<Map<String, dynamic>> getDashboardStats({String period = 'month', int? selectedYear}) async {
    final now = DateTime.now();
    DateTime startDate;

    if (period == 'week') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (period == 'year') {
      final year = selectedYear ?? now.year;
      startDate = DateTime(year, 1, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1);
    }

    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfMonth = DateTime(now.year, now.month, 1);
    const double revenuePerPhoto = 800.0; // 2 credits = 800 TZS

    int totalUsers = 0;
    int newUsersToday = 0;
    int totalPhotos = 0;
    int photosToday = 0;
    int photosMonth = 0;
    double totalRevenue = 0;
    double revenueToday = 0;
    double revenueMonth = 0;
    double periodRevenue = 0;
    Map<String, int> packageCounts = {};
    Map<int, double> monthlySales = {};
    int totalApiTokens = 100000;

    // 1. Get users (safe)
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      totalUsers = usersSnapshot.docs.length;
      newUsersToday = usersSnapshot.docs.where((doc) {
        final createdAt = _parseDate(doc.data()['createdAt']);
        return createdAt != null && createdAt.isAfter(startOfToday);
      }).length;
    } catch (e) {
      debugPrint('Dashboard: error loading users: $e');
    }

    // 2. Get photos (safe)
    try {
      final photosSnapshot = await _firestore.collection('photos').get();
      totalPhotos = photosSnapshot.docs.length;

      photosToday = photosSnapshot.docs.where((doc) {
        final createdAt = _parseDate(doc.data()['createdAt']);
        return createdAt != null && createdAt.isAfter(startOfToday);
      }).length;

      photosMonth = photosSnapshot.docs.where((doc) {
        final createdAt = _parseDate(doc.data()['createdAt']);
        return createdAt != null && createdAt.isAfter(startOfMonth);
      }).length;

      // Calculate revenue from photos
      totalRevenue = totalPhotos * revenuePerPhoto;
      revenueToday = photosToday * revenuePerPhoto;
      revenueMonth = photosMonth * revenuePerPhoto;

      // Monthly chart data
      final chartYear = selectedYear ?? now.year;
      for (var doc in photosSnapshot.docs) {
        final createdAt = _parseDate(doc.data()['createdAt']);
        if (createdAt != null && createdAt.year == chartYear) {
          final month = createdAt.month;
          monthlySales[month] = (monthlySales[month] ?? 0) + revenuePerPhoto;
        }
      }

      // Period revenue
      final periodPhotos = photosSnapshot.docs.where((doc) {
        final createdAt = _parseDate(doc.data()['createdAt']);
        return createdAt != null && createdAt.isAfter(startDate);
      }).length;
      periodRevenue = periodPhotos * revenuePerPhoto;

    } catch (e) {
      debugPrint('Dashboard: error loading photos: $e');
    }

    // 3. Get transactions for revenue calculation (safe)
    try {
      // Use simple query without .where() filter to avoid index issues
      final transactionsSnapshot = await _firestore
          .collection('transactions')
          .get();

      // Calculate revenue from ALL transactions (purchases have amount)
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString() ?? '';
        final createdAt = _parseDate(data['createdAt']);
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final description = data['description']?.toString() ?? '';

        // Only count purchase transactions for revenue if no photos exist
        if (type == 'purchase' && totalPhotos == 0) {
          totalRevenue += amount;
          if (createdAt != null) {
            if (createdAt.isAfter(startOfToday)) revenueToday += amount;
            if (createdAt.isAfter(startOfMonth)) revenueMonth += amount;
            if (createdAt.isAfter(startDate)) periodRevenue += amount;

            final chartYear = selectedYear ?? now.year;
            if (createdAt.year == chartYear) {
              final month = createdAt.month;
              monthlySales[month] = (monthlySales[month] ?? 0) + amount;
            }
          }
        }

        // Track package popularity
        if (type == 'purchase' && createdAt != null && createdAt.isAfter(startDate)) {
          final packageName = _extractPackageName(description);
          if (packageName.isNotEmpty) {
            packageCounts[packageName] = (packageCounts[packageName] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      debugPrint('Dashboard: error loading transactions: $e');
    }

    // 4. Get system settings (safe)
    try {
      final settingsDoc = await _firestore.collection('config').doc('system').get();
      if (settingsDoc.exists) {
        totalApiTokens = (settingsDoc.data()?['totalApiTokens'] as int?) ?? 100000;
      }
    } catch (e) {
      debugPrint('Dashboard: error loading system settings: $e');
    }

    final apiTokensUsed = totalPhotos;
    final apiTokensRemaining = totalApiTokens - apiTokensUsed;

    // Build monthly sales data for chart (all 12 months)
    final monthlySalesData = List.generate(12, (index) {
      final month = index + 1;
      return {
        'month': month,
        'name': _getMonthName(month),
        'value': monthlySales[month] ?? 0.0,
      };
    });

    return {
      'totalUsers': totalUsers,
      'newUsersToday': newUsersToday,
      'totalPhotos': totalPhotos,
      'photosToday': photosToday,
      'totalRevenue': totalRevenue,
      'revenueToday': revenueToday,
      'revenueMonth': revenueMonth,
      'periodRevenue': periodRevenue,
      'trendingPackages': packageCounts.entries.map((e) => {'name': e.key, 'value': e.value.toDouble()}).toList(),
      'monthlySales': monthlySalesData,
      'apiTokensUsed': apiTokensUsed,
      'apiTokensRemaining': apiTokensRemaining,
      'totalApiTokens': totalApiTokens,
      'apiTokenUsage': apiTokensUsed,
    };
  }

  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 5}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('totalSpent', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'Unknown',
        'spent': (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
        'photos': (data['totalPhotosProcessed'] as num?)?.toInt() ?? 0,
        'credits': (data['credits'] as num?)?.toInt() ?? 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTopPackages({int limit = 5}) async {
    final snapshot = await _firestore
        .collection('packages')
        .orderBy('sales', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final sales = (data['sales'] as num?)?.toInt() ?? 0;
      return {
        'name': data['name'] ?? 'Unknown',
        'sales': sales,
        'revenue': sales * price,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    List<Map<String, dynamic>> activities = [];

    // 1. Get recent users
    final users = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (var doc in users.docs) {
      final data = doc.data();
      activities.add({
        'type': 'user',
        'title': 'New user registered',
        'subtitle': '${data['name'] ?? 'Someone'} joined',
        'icon': 'person_add',
        'color': 'primary',
        'createdAt': data['createdAt'],
      });
    }

    // 2. Get recent photos
    final photos = await _firestore
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (var doc in photos.docs) {
      final data = doc.data();
      activities.add({
        'type': 'photo',
        'title': 'Photo processed',
        'subtitle': 'AI processing completed',
        'icon': 'auto_awesome',
        'color': 'accent',
        'createdAt': data['createdAt'],
      });
    }

    // 3. Get recent transactions
    final txs = await _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    for (var doc in txs.docs) {
      final data = doc.data();
      activities.add({
        'type': 'transaction',
        'title': 'Payment received',
        'subtitle': 'TZS ${data['amount'] ?? 0} from ${data['userId']?.toString().substring(0, 5) ?? 'User'}...',
        'icon': 'payment',
        'color': 'success',
        'createdAt': data['createdAt'],
      });
    }

    // Sort all by date
    activities.sort((a, b) {
      final dateA = _parseDate(a['createdAt']) ?? DateTime(2000);
      final dateB = _parseDate(b['createdAt']) ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return activities.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getTrendingPackages() async {
    // This is a mock/aggregated view of which packages are bought most
    // In a real app, you'd aggregate the transactions collection
    final txs = await _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'purchase')
        .get();

    Map<String, int> counts = {};

    for (var doc in txs.docs) {
      final desc = doc.data()['description']?.toString() ?? '';
      final packageName = _extractPackageName(desc);
      if (packageName.isNotEmpty) {
        counts[packageName] = (counts[packageName] ?? 0) + 1;
      }
    }

    return counts.entries.map((e) => {'name': e.key, 'value': e.value.toDouble()}).toList();
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is Timestamp) return dateValue.toDate();
    if (dateValue is String) return DateTime.tryParse(dateValue);
    return null;
  }

  String _extractPackageName(String description) {
    // Extract package name from description like "Purchase of Basic Package"
    final match = RegExp(r'Purchase of\s+([^\s]+)').firstMatch(description);
    return match?.group(1) ?? '';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month.clamp(1, 12)) - 1];
  }

  // ============================================
  // CUSTOMERS OPERATIONS
  // ============================================

  // Get all customers
  Future<List<CustomerModel>> getCustomers({int limit = 50}) async {
    final query = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList();
  }

  // Create customer
  Future<void> createCustomer(CustomerModel customer) async {
    await _firestore.collection('users').add(customer.toMap());
  }

  // Update customer
  Future<void> updateCustomer(CustomerModel customer) async {
    await _firestore.collection('users').doc(customer.id).update(customer.toMap());
  }

  // Stream customers (realtime)
  Stream<List<CustomerModel>> streamCustomers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList());
  }

  // Search customers
  Future<List<CustomerModel>> searchCustomers(String query) async {
    // Search by email (Firestore doesn't support full-text search natively)
    final emailResults = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('email', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .limit(20)
        .get();

    return emailResults.docs.map((doc) => CustomerModel.fromFirestore(doc)).toList();
  }

  // Get customer by ID
  Future<CustomerModel?> getCustomer(String customerId) async {
    final doc = await _firestore.collection('users').doc(customerId).get();
    if (doc.exists) {
      return CustomerModel.fromFirestore(doc);
    }
    return null;
  }

  // Toggle customer active status
  Future<void> toggleCustomerStatus(String customerId, bool isActive) async {
    await _firestore.collection('users').doc(customerId).update({
      'isActive': isActive,
    });
  }

  // Add credits to customer
  Future<void> addCreditsToCustomer(String customerId, int amount, {String? reason}) async {
    final customerDoc = await _firestore.collection('users').doc(customerId).get();
    if (!customerDoc.exists) return;

    final currentCredits = customerDoc.data()?['credits'] ?? 0;

    await _firestore.collection('users').doc(customerId).update({
      'credits': currentCredits + amount,
    });

    // Log transaction
    await _firestore.collection('transactions').add({
      'userId': customerId,
      'type': 'bonus',
      'credits': amount,
      'description': reason ?? 'Admin credit bonus',
      'createdAt': Timestamp.now(),
    });
  }

  // ============================================
  // PHOTOS OPERATIONS
  // ============================================

  // Get all photos
  Future<List<PhotoModel>> getPhotos({int limit = 50, String? status}) async {
    Query query = _firestore
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PhotoModel.fromFirestore(doc as DocumentSnapshot)).toList();
  }

  // Update photo status
  Future<void> updatePhotoStatus(String photoId, String status) async {
    await _firestore.collection('photos').doc(photoId).update({
      'status': status,
    });
  }

  // Delete photo
  Future<void> deletePhoto(String photoId) async {
    await _firestore.collection('photos').doc(photoId).delete();
  }

  // Stream photos (realtime)
  Stream<List<PhotoModel>> streamPhotos() {
    return _firestore
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PhotoModel.fromFirestore(doc)).toList());
  }

  // Get customer's photos
  Future<List<PhotoModel>> getCustomerPhotos(String customerId) async {
    final snapshot = await _firestore
        .collection('photos')
        .where('userId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => PhotoModel.fromFirestore(doc)).toList();
  }

  // ============================================
  // TRANSACTIONS OPERATIONS
  // ============================================

  // Get paginated transactions
  Future<List<TransactionModel>> getPaginatedTransactions({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
  }

  // Stream transactions (realtime)
  Stream<List<TransactionModel>> streamTransactions() {
    return _firestore
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
  }

  // Get customer's transactions
  Future<List<TransactionModel>> getCustomerTransactions(String customerId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
  }

  // ============================================
  // SEED INITIAL ADMIN
  // ============================================

  Future<void> seedInitialAdmin({
    required String uid,
    required String email,
    required String name,
  }) async {
    final adminDoc = await _firestore.collection('admins').doc(uid).get();
    if (!adminDoc.exists) {
      await _firestore.collection('admins').doc(uid).set({
        'email': email,
        'name': name,
        'role': 'super_admin',
        'isActive': true,
        'isApproved': true,
        'createdAt': Timestamp.now(),
      });
    }
  }

  /// Ensure default admin credentials config exists in Firestore
  Future<void> ensureAdminDefaultsConfig() async {
    final configDoc = await _firestore.collection('config').doc('admin_defaults').get();
    if (!configDoc.exists) {
      await _firestore.collection('config').doc('admin_defaults').set({
        'email': 'admin@picsell.com',
        'password': 'admin@picsell',
        'name': 'Super Admin',
        'seeded': false,
        'createdAt': Timestamp.now(),
      });
    }
  }

  // ============================================
  // PACKAGES OPERATIONS
  // ============================================

  // Get packages stream
  Stream<List<PackageModel>> streamPackages() {
    return _firestore
        .collection('packages')
        .orderBy('price', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PackageModel.fromFirestore(doc)).toList());
  }

  // Create package
  Future<void> createPackage(PackageModel package) async {
    // Convert to map but remove null ID if present (though our model has non-nullable ID, 
    // we usually generate ID from firestore or let firestore gen it)
    // Actually, toMap includes everything. We might want to exclude ID if we want auto-ID.
    // But let's assume we use the map as is, or we use .add() which ignores ID in doc data usually unless specified.
    
    // Better approach for create: unique ID or auto ID.
    // If Model has ID, we might want to use .set() on that ID, or .add() and ignore the model's ID field for now.
    // Let's use .add() and let Firestore generate ID, then we don't need to send 'id' in the map.
    // However, our toMap() doesn't include ID. (Wait, let me check model).
    
    // Checked model: toMap DOES NOT include 'id'. Good.
    
    await _firestore.collection('packages').add(package.toMap());
  }

  // Update package
  Future<void> updatePackage(PackageModel package) async {
    await _firestore
        .collection('packages')
        .doc(package.id)
        .update(package.toMap());
  }

  // Delete package
  Future<void> deletePackage(String packageId) async {
    await _firestore.collection('packages').doc(packageId).delete();
  }

  // Toggle package active status
  Future<void> togglePackageStatus(String packageId, bool isActive) async {
    await _firestore.collection('packages').doc(packageId).update({
      'isActive': isActive,
    });
  }

  // ============================================
  // NOTIFICATIONS OPERATIONS
  // ============================================

  // Send notification
  Future<void> sendNotification({
    required String title,
    required String body,
    required String userId, // 'all' or specific userId
    String type = 'info',
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'body': body,
      'userId': userId,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream notifications (for admin history/view)
  Stream<List<NotificationModel>> streamNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  // ============================================
  // SYSTEM SETTINGS
  // ============================================

  Future<SystemSettingsModel> getSystemSettings() async {
    final doc = await _firestore.collection('config').doc('system').get();
    return SystemSettingsModel.fromFirestore(doc);
  }

  Future<void> updateSystemSettings(SystemSettingsModel settings) async {
    await _firestore.collection('config').doc('system').set(settings.toMap(), SetOptions(merge: true));
  }

  // ============================================
  // REPORTS HISTORY
  // ============================================

  Future<void> saveReport(Map<String, dynamic> reportData) async {
    await _firestore.collection('reports').add({
      ...reportData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamReportHistory() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList());
  }

  Future<void> deleteReport(String reportId) async {
    await _firestore.collection('reports').doc(reportId).delete();
  }

  // ============================================
  // ADMIN USERS
  // ============================================

  Future<List<AdminModel>> getAdminUsers() async {
    final snapshot = await _firestore.collection('admins').get();
    return snapshot.docs.map((doc) => AdminModel.fromFirestore(doc)).toList();
  }

  Future<void> updateAdminUser(AdminModel admin) async {
    await _firestore.collection('admins').doc(admin.id).update(admin.toFirestore());
  }

  Future<void> deleteAdminUser(String adminId) async {
    await _firestore.collection('admins').doc(adminId).delete();
  }

  // ============================================
  // ADVERTISEMENTS
  // ============================================

  Stream<List<Map<String, dynamic>>> streamAdvertisements() {
    return _firestore
        .collection('advertisements')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> createAdvertisement({
    required String imageUrl,
    required String title,
    required String subtitle,
    required bool isActive,
    required DateTime expiresAt,
  }) async {
    final snap = await _firestore.collection('advertisements').get();
    final order = snap.docs.length;
    await _firestore.collection('advertisements').add({
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'isActive': isActive,
      'order': order,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAdvertisement(String id, Map<String, dynamic> data) async {
    await _firestore.collection('advertisements').doc(id).update(data);
  }

  Future<void> deleteAdvertisement(String id) async {
    await _firestore.collection('advertisements').doc(id).delete();
  }
}
