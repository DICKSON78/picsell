class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final int credits;
  final int totalCreditsPurchased;
  final int totalPhotosProcessed;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastActive;
  final String? picture;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.credits,
    required this.totalCreditsPurchased,
    required this.totalPhotosProcessed,
    required this.isActive,
    required this.createdAt,
    required this.lastActive,
    this.picture,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    int? credits,
    int? totalCreditsPurchased,
    int? totalPhotosProcessed,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastActive,
    String? picture,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      credits: credits ?? this.credits,
      totalCreditsPurchased: totalCreditsPurchased ?? this.totalCreditsPurchased,
      totalPhotosProcessed: totalPhotosProcessed ?? this.totalPhotosProcessed,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      picture: picture ?? this.picture,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      credits: json['credits'] ?? 0,
      totalCreditsPurchased: json['totalCreditsPurchased'] ?? 0,
      totalPhotosProcessed: json['totalPhotosProcessed'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : DateTime.now(),
      picture: json['picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'credits': credits,
      'totalCreditsPurchased': totalCreditsPurchased,
      'totalPhotosProcessed': totalPhotosProcessed,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'picture': picture,
    };
  }
}
