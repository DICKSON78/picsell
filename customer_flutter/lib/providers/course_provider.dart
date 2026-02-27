import 'package:flutter/foundation.dart';
import '../models/course.dart';

class CourseProvider with ChangeNotifier {
  List<Course> _courses = [];
  List<Course> _cartCourses = [];
  List<Course> _purchasedCourses = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Course> get courses => [..._courses];
  List<Course> get cartCourses => [..._cartCourses];
  List<Course> get purchasedCourses => [..._purchasedCourses];
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get cartTotal {
    return _cartCourses.fold(0.0, (sum, course) => sum + course.price);
  }
  
  int get cartItemCount => _cartCourses.length;

  // Initialize courses
  Future<void> loadCourses() async {
    _setLoading(true);
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _courses = MockCourses.getCourses();
      
      // Filter purchased courses (for demo, first 2 are purchased)
      _purchasedCourses = _courses.where((course) => course.isPurchased).toList();
      
      // Filter cart courses (for demo, course 3 is in cart)
      _cartCourses = _courses.where((course) => course.isInCart).toList();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to load courses: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Add to cart
  void addToCart(Course course) {
    if (!_cartCourses.contains(course)) {
      _cartCourses.add(course.copyWith(isInCart: true));
      
      // Update the course in the main list
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = _courses[index].copyWith(isInCart: true);
      }
      
      notifyListeners();
    }
  }

  // Remove from cart
  void removeFromCart(Course course) {
    _cartCourses.removeWhere((c) => c.id == course.id);
    
    // Update the course in the main list
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = _courses[index].copyWith(isInCart: false);
    }
    
    notifyListeners();
  }

  // Purchase course
  Future<void> purchaseCourse(Course course) async {
    _setLoading(true);
    try {
      // Simulate purchase process
      await Future.delayed(const Duration(seconds: 2));
      
      // Remove from cart
      _cartCourses.removeWhere((c) => c.id == course.id);
      
      // Add to purchased courses
      _purchasedCourses.add(course.copyWith(isPurchased: true, isInCart: false));
      
      // Update the course in the main list
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = _courses[index].copyWith(
          isPurchased: true,
          isInCart: false,
        );
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to purchase course: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Purchase all cart items
  Future<void> purchaseCart() async {
    _setLoading(true);
    try {
      // Simulate purchase process
      await Future.delayed(const Duration(seconds: 3));
      
      // Move all cart courses to purchased
      for (final course in _cartCourses) {
        _purchasedCourses.add(course.copyWith(isPurchased: true, isInCart: false));
        
        // Update in main list
        final index = _courses.indexWhere((c) => c.id == course.id);
        if (index != -1) {
          _courses[index] = _courses[index].copyWith(
            isPurchased: true,
            isInCart: false,
          );
        }
      }
      
      // Clear cart
      _cartCourses.clear();
      
      _error = null;
    } catch (e) {
      _error = 'Failed to complete purchase: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Update course progress
  void updateCourseProgress(String courseId, double progress) {
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _courses[index] = _courses[index].copyWith(progress: progress);
      
      // Also update in purchased courses if it exists there
      final purchasedIndex = _purchasedCourses.indexWhere((c) => c.id == courseId);
      if (purchasedIndex != -1) {
        _purchasedCourses[purchasedIndex] = _purchasedCourses[purchasedIndex].copyWith(progress: progress);
      }
      
      notifyListeners();
    }
  }

  // Get course by ID
  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  // Get courses by category
  List<Course> getCoursesByCategory(String category) {
    return _courses.where((course) => course.category == category).toList();
  }

  // Search courses
  List<Course> searchCourses(String query) {
    if (query.isEmpty) return _courses;
    
    return _courses.where((course) {
      return course.title.toLowerCase().contains(query.toLowerCase()) ||
             course.description.toLowerCase().contains(query.toLowerCase()) ||
             course.instructor.toLowerCase().contains(query.toLowerCase()) ||
             course.category.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh courses
  Future<void> refreshCourses() async {
    await loadCourses();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
