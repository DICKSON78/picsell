import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS simulator

  String? _authToken;

  // Image cache: hash -> processed image URL
  final Map<String, String> _imageCache = {};

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get stored auth token
  Future<String?> getToken() async {
    if (_authToken != null) return _authToken;
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    return _authToken;
  }

  // Store auth token
  Future<void> setToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear auth token (logout)
  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
  // AUTH ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String countryCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'phone': '$countryCode$phone',
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data['token'] != null) {
        await setToken(data['token']);
      }
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['token'] != null) {
        await setToken(data['token']);
      }
      return data;
    } else {
      throw Exception(data['error'] ?? 'OTP verification failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
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

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get profile');
    }
  }

  // ============================================
  // IMAGE CACHING
  // ============================================

  // Generate hash for image file
  Future<String> _generateImageHash(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // Check if image is cached
  String? getCachedProcessedUrl(String imageHash) {
    return _imageCache[imageHash];
  }

  // Store processed image in cache
  void cacheProcessedImage(String imageHash, String processedUrl) {
    _imageCache[imageHash] = processedUrl;
  }

  // ============================================
  // PHOTO ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> processPhoto(File imageFile, {bool checkCache = true}) async {
    // Generate hash for duplicate detection
    final imageHash = await _generateImageHash(imageFile);

    // Check if we already processed this exact image
    if (checkCache) {
      final cachedUrl = getCachedProcessedUrl(imageHash);
      if (cachedUrl != null) {
        // Return cached result - credit will still be deducted via deductCredit call
        return {
          'success': true,
          'fromCache': true,
          'photo': {
            'id': 'cached_$imageHash',
            'processedUrl': cachedUrl,
            'status': 'completed',
          },
          'imageHash': imageHash,
        };
      }
    }

    final token = await getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/photos/process'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Cache the processed image URL
      if (data['photo'] != null && data['photo']['processedUrl'] != null) {
        cacheProcessedImage(imageHash, data['photo']['processedUrl']);
      }
      data['imageHash'] = imageHash;
      data['fromCache'] = false;
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to process photo');
    }
  }

  // Deduct credit for cached image
  Future<Map<String, dynamic>> deductCredit() async {
    final response = await http.post(
      Uri.parse('$baseUrl/credits/deduct'),
      headers: await _getHeaders(),
      body: jsonEncode({'amount': 1}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to deduct credit');
    }
  }

  Future<Map<String, dynamic>> downloadPhoto(String photoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/photos/download/$photoId'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to download photo');
    }
  }

  Future<List<Map<String, dynamic>>> getPhotoHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/photos/history'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data['photos'] ?? []);
    } else {
      throw Exception(data['error'] ?? 'Failed to get photo history');
    }
  }

  // ============================================
  // CREDITS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getCredits() async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/balance'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get credits');
    }
  }

  // Create ClickPesa payment request
  Future<Map<String, dynamic>> createPayment({
    required String packageId,
    String? phoneNumber,
    required String paymentMethod,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/credits/create-payment'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'packageId': packageId,
        'phoneNumber': phoneNumber,
        'paymentMethod': paymentMethod,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to create payment');
    }
  }

  // Initiate ClickPesa USSD payment
  Future<Map<String, dynamic>> initiatePayment({
    required String orderReference,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/credits/initiate-payment'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'orderReference': orderReference,
        'phoneNumber': phoneNumber,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to initiate payment');
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String orderReference) async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/transactions?orderReference=$orderReference'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to check payment status');
    }
  }

  // Save bank details
  Future<Map<String, dynamic>> saveBankDetails({
    required String accountNumber,
    required String accountName,
    required String bankName,
    bool isDefault = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/credits/save-bank-details'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'accountNumber': accountNumber,
        'accountName': accountName,
        'bankName': bankName,
        'isDefault': isDefault,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to save bank details');
    }
  }

  // Get bank details
  Future<Map<String, dynamic>> getBankDetails() async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/bank-details'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get bank details');
    }
  }

  // Get exchange rate
  Future<Map<String, dynamic>> getExchangeRate() async {
    final response = await http.get(
      Uri.parse('$baseUrl/credits/exchange-rate'),
      headers: await _getHeaders(),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to get exchange rate');
    }
  }

  // Legacy method for backward compatibility
  Future<Map<String, dynamic>> purchaseCredits({
    required String packageId,
    required String paymentMethod,
  }) async {
    if (paymentMethod == 'clickpesa') {
      // Return error - phone number required for ClickPesa
      throw Exception('Phone number required for ClickPesa payment');
    }
    
    // Fallback to other payment methods
    final response = await http.post(
      Uri.parse('$baseUrl/credits/purchase'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'packageId': packageId,
        'paymentMethod': paymentMethod,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to purchase credits');
    }
  }

  // Get full URL for images
  String getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${baseUrl.replaceAll('/api', '')}/$path';
  }
}
