import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../models/photo_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class CustomersProvider with ChangeNotifier {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;
  List<PhotoModel> _customerPhotos = [];
  List<TransactionModel> _customerTransactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CustomerModel> get customers => _customers;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  List<PhotoModel> get customerPhotos => _customerPhotos;
  List<TransactionModel> get customerTransactions => _customerTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _firestoreService.getCustomers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search customers
  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      await loadCustomers();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _firestoreService.searchCustomers(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a customer and load their details
  Future<void> selectCustomer(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedCustomer = await _firestoreService.getCustomer(customerId);
      if (_selectedCustomer != null) {
        _customerPhotos = await _firestoreService.getCustomerPhotos(customerId);
        _customerTransactions = await _firestoreService.getCustomerTransactions(customerId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle customer status
  Future<void> toggleCustomerStatus(String customerId, bool isActive) async {
    try {
      await _firestoreService.toggleCustomerStatus(customerId, isActive);

      // Update local list
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(isActive: isActive);
        notifyListeners();
      }

      // Update selected customer if applicable
      if (_selectedCustomer?.id == customerId) {
        _selectedCustomer = _selectedCustomer!.copyWith(isActive: isActive);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add credits to customer
  Future<void> addCredits(String customerId, int amount, {String? reason}) async {
    try {
      await _firestoreService.addCreditsToCustomer(customerId, amount, reason: reason);

      // Reload customer details
      if (_selectedCustomer?.id == customerId) {
        await selectCustomer(customerId);
      }

      // Update local list
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        _customers[index] = _customers[index].copyWith(
          credits: _customers[index].credits + amount,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add new customer
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _firestoreService.createCustomer(customer);
      await loadCustomers(); // Refresh list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update existing customer
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _firestoreService.updateCustomer(customer);
      
      // Update local list
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        notifyListeners();
      }
      
      if (_selectedCustomer?.id == customer.id) {
        _selectedCustomer = customer;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear selected customer
  void clearSelectedCustomer() {
    _selectedCustomer = null;
    _customerPhotos = [];
    _customerTransactions = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
