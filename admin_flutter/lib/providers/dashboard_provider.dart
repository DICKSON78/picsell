import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class DashboardProvider with ChangeNotifier {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _trendingPackages = [];
  List<Map<String, dynamic>> _monthlySales = [];
  List<dynamic> _transactions = [];
  String _currentPeriod = 'month';
  int _selectedYear = DateTime.now().year;
  int _chartYear = DateTime.now().year;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get activities => _activities;
  List<Map<String, dynamic>> get trendingPackages => _trendingPackages;
  List<Map<String, dynamic>> get monthlySales => _monthlySales;
  List<dynamic> get transactions => _transactions;
  String get currentPeriod => _currentPeriod;
  int get selectedYear => _selectedYear;
  int get chartYear => _chartYear;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalUsers => _stats['totalUsers'] ?? 0;
  int get newUsersToday => _stats['newUsersToday'] ?? 0;
  int get newUsersMonth => _stats['newUsersMonth'] ?? 0;
  int get totalPhotos => _stats['totalPhotos'] ?? 0;
  int get photosToday => _stats['photosToday'] ?? 0;
  double get totalRevenue => _stats['totalRevenue'] ?? 0.0;
  double get revenueToday => _stats['revenueToday'] ?? 0.0;
  double get revenueMonth => _stats['revenueMonth'] ?? 0.0;
  double get periodRevenue => _stats['periodRevenue'] ?? 0.0;
  int get apiTokenUsage => _stats['apiTokenUsage'] ?? 0;
  int get apiTokensUsed => _stats['apiTokensUsed'] ?? 0;
  int get apiTokensRemaining => _stats['apiTokensRemaining'] ?? 0;
  int get totalApiTokens => _stats['totalApiTokens'] ?? 100000;

  Future<void> loadStats({String? period}) async {
    if (period != null) _currentPeriod = period;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _firestoreService.getDashboardStats(
        period: _currentPeriod,
        selectedYear: _chartYear,
      );

      _activities = await _firestoreService.getRecentActivity(limit: 4);

      _trendingPackages = (_stats['trendingPackages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _monthlySales = (_stats['monthlySales'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      _transactions = await _firestoreService.getPaginatedTransactions(limit: 10);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTransactions() async {
    try {
      // Find last doc for pagination (simplified for now, ideally store last doc snapshot)
      // But for simplicity in this mockup flow:
      // final lastDoc = ...
      // final more = await _firestoreService.getPaginatedTransactions(limit: 10, lastDocument: lastDoc);
      // _transactions.addAll(more);
      // notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setPeriod(String period) {
    _currentPeriod = period;
    loadStats();
  }

  void setYear(int year) {
    _selectedYear = year;
    loadStats();
  }

  void setChartYear(int year) {
    _chartYear = year;
    loadStats();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
