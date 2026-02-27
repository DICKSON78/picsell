import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator

  String? _authToken;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get stored auth token
  Future<String?> getToken() async {
    if (_authToken != null) return _authToken;
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('admin_token');
    return _authToken;
  }

  // Store auth token
  Future<void> setToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_token', token);
  }

  // Clear auth token (logout)
  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ============================================
  // CLICKPESA ENDPOINTS
  // ============================================

  // Get ClickPesa account balance
  Future<Map<String, dynamic>> getClickPesaBalance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/clickpesa-balance'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get ClickPesa balance');
    }
  }

  // Get ClickPesa transactions
  Future<Map<String, dynamic>> getClickPesaTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/clickpesa-transactions'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get ClickPesa transactions');
    }
  }

  // Initiate ClickPesa payout
  Future<Map<String, dynamic>> initiateClickPesaPayout({
    required String phoneNumber,
    required int amount,
    required String orderReference,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/clickpesa-payout'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'amount': amount,
        'orderReference': orderReference,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to initiate ClickPesa payout');
    }
  }

  // ============================================
  // AUTH ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['token'] != null) {
        await setToken(data['token']);
      }
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/me'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get admin info');
    }
  }

  // ============================================
  // DASHBOARD ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get dashboard stats');
    }
  }

  // ============================================
  // CUSTOMERS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    String url = '$baseUrl/admin/customers?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get customers');
    }
  }

  Future<Map<String, dynamic>> getCustomer(String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/customers/$customerId'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get customer');
    }
  }

  Future<Map<String, dynamic>> addCredits({
    required String customerId,
    required int credits,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/customers/$customerId/credits'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'credits': credits,
        'reason': reason,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to add credits');
    }
  }

  // ============================================
  // PHOTOS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getPhotos({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    String url = '$baseUrl/admin/photos?page=$page&limit=$limit';
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get photos');
    }
  }

  // ============================================
  // TRANSACTIONS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    String url = '$baseUrl/admin/transactions?page=$page&limit=$limit';
    if (type != null && type.isNotEmpty) {
      url += '&type=$type';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get transactions');
    }
  }

  // ============================================
  // REPORTS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getReports({int days = 30}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/reports?days=$days'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get reports');
    }
  }

  // ============================================
  // UTILITY
  // ============================================

  // Get full URL for images
  String getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${baseUrl.replaceAll('/api', '')}/$path';
  }

  // Health check
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl.replaceAll('/api', '')}/api/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
