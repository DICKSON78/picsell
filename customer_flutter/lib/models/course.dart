class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final double price;
  final double rating;
  final int duration; // in hours
  final String imageUrl;
  final String category;
  final double progress; // 0.0 to 1.0
  final int enrolledCount;
  final List<String> topics;
  final bool isPurchased;
  final bool isInCart;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.price,
    required this.rating,
    required this.duration,
    required this.imageUrl,
    required this.category,
    this.progress = 0.0,
    this.enrolledCount = 0,
    this.topics = const [],
    this.isPurchased = false,
    this.isInCart = false,
  });

  // Copy with method for immutability
  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? instructor,
    double? price,
    double? rating,
    int? duration,
    String? imageUrl,
    String? category,
    double? progress,
    int? enrolledCount,
    List<String>? topics,
    bool? isPurchased,
    bool? isInCart,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      topics: topics ?? this.topics,
      isPurchased: isPurchased ?? this.isPurchased,
      isInCart: isInCart ?? this.isInCart,
    );
  }

  // From JSON
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      instructor: json['instructor'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      duration: json['duration'] as int,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      enrolledCount: json['enrolledCount'] as int? ?? 0,
      topics: List<String>.from(json['topics'] as List? ?? []),
      isPurchased: json['isPurchased'] as bool? ?? false,
      isInCart: json['isInCart'] as bool? ?? false,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'price': price,
      'rating': rating,
      'duration': duration,
      'imageUrl': imageUrl,
      'category': category,
      'progress': progress,
      'enrolledCount': enrolledCount,
      'topics': topics,
      'isPurchased': isPurchased,
      'isInCart': isInCart,
    };
  }

  // Getters
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedDuration => '${duration}h';
  String get progressPercentage => '${(progress * 100).toInt()}%';
  bool get isCompleted => progress >= 1.0;
  bool get hasStarted => progress > 0.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Course(id: $id, title: $title, progress: $progressPercentage)';
  }
}

// Mock data for demonstration
class MockCourses {
  static List<Course> getCourses() {
    return [
      Course(
        id: '1',
        title: 'Design Thinking Skills',
        description: 'Learn the fundamentals of design thinking and apply them to real-world problems.',
        instructor: 'Sarah Johnson',
        price: 49.99,
        rating: 4.5,
        duration: 8,
        imageUrl: 'https://picsum.photos/seed/design-thinking/400/300.jpg',
        category: 'Design',
        progress: 0.75,
        enrolledCount: 1234,
        topics: ['Empathy', 'Ideation', 'Prototyping', 'Testing'],
        isPurchased: true,
      ),
      Course(
        id: '2',
        title: 'Principles of Design',
        description: 'Master the core principles that govern great design across all mediums.',
        instructor: 'Michael Chen',
        price: 79.99,
        rating: 4.8,
        duration: 12,
        imageUrl: 'https://picsum.photos/seed/principles-design/400/300.jpg',
        category: 'Design',
        progress: 0.30,
        enrolledCount: 892,
        topics: ['Balance', 'Hierarchy', 'Contrast', 'Repetition'],
        isPurchased: true,
      ),
      Course(
        id: '3',
        title: 'iOS Design Basics',
        description: 'Learn the fundamentals of iOS app design and Apple\'s Human Interface Guidelines.',
        instructor: 'Emily Rodriguez',
        price: 89.99,
        rating: 4.7,
        duration: 10,
        imageUrl: 'https://picsum.photos/seed/ios-design/400/300.jpg',
        category: 'Mobile Design',
        progress: 0.0,
        enrolledCount: 567,
        topics: ['HIG', 'Navigation', 'Controls', 'Layout'],
        isPurchased: false,
        isInCart: true,
      ),
      Course(
        id: '4',
        title: 'User Experience Fundamentals',
        description: 'Understand the core concepts of UX design and user-centered thinking.',
        instructor: 'David Kim',
        price: 69.99,
        rating: 4.6,
        duration: 15,
        imageUrl: 'https://picsum.photos/seed/ux-fundamentals/400/300.jpg',
        category: 'UX Design',
        progress: 0.0,
        enrolledCount: 2341,
        topics: ['Research', 'Personas', 'Journey Maps', 'Usability'],
        isPurchased: false,
        isInCart: false,
      ),
      Course(
        id: '5',
        title: 'Color Theory for Designers',
        description: 'Master color theory and its application in digital and print design.',
        instructor: 'Lisa Anderson',
        price: 39.99,
        rating: 4.4,
        duration: 6,
        imageUrl: 'https://picsum.photos/seed/color-theory/400/300.jpg',
        category: 'Design',
        progress: 0.90,
        enrolledCount: 1567,
        topics: ['Color Wheel', 'Harmony', 'Psychology', 'Application'],
        isPurchased: true,
      ),
    ];
  }
}
