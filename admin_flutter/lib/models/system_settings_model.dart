import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsModel {
  final bool maintenanceMode;
  final bool autoApprovePhotos;
  final bool pushNotifications;
  final bool emailNotifications;
  final int defaultWelcomeCredits;
  final int maxPhotosPerDay;
  final String selectedLanguage;
  final int totalApiTokens; // Total purchased API tokens

  SystemSettingsModel({
    required this.maintenanceMode,
    required this.autoApprovePhotos,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.defaultWelcomeCredits,
    required this.maxPhotosPerDay,
    this.selectedLanguage = 'English',
    this.totalApiTokens = 100000, // Default 100k tokens
  });

  factory SystemSettingsModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return SystemSettingsModel.defaultSettings();
    }
    final data = doc.data() as Map<String, dynamic>;
    return SystemSettingsModel(
      maintenanceMode: data['maintenanceMode'] ?? false,
      autoApprovePhotos: data['autoApprovePhotos'] ?? false,
      pushNotifications: data['pushNotifications'] ?? true,
      emailNotifications: data['emailNotifications'] ?? true,
      defaultWelcomeCredits: data['defaultWelcomeCredits'] ?? 5,
      maxPhotosPerDay: data['maxPhotosPerDay'] ?? 50,
      selectedLanguage: data['selectedLanguage'] ?? 'English',
      totalApiTokens: data['totalApiTokens'] ?? 100000,
    );
  }

  factory SystemSettingsModel.defaultSettings() {
    return SystemSettingsModel(
      maintenanceMode: false,
      autoApprovePhotos: false,
      pushNotifications: true,
      emailNotifications: true,
      defaultWelcomeCredits: 5,
      maxPhotosPerDay: 50,
      selectedLanguage: 'English',
      totalApiTokens: 100000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maintenanceMode': maintenanceMode,
      'autoApprovePhotos': autoApprovePhotos,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'defaultWelcomeCredits': defaultWelcomeCredits,
      'maxPhotosPerDay': maxPhotosPerDay,
      'selectedLanguage': selectedLanguage,
      'totalApiTokens': totalApiTokens,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SystemSettingsModel copyWith({
    bool? maintenanceMode,
    bool? autoApprovePhotos,
    bool? pushNotifications,
    bool? emailNotifications,
    int? defaultWelcomeCredits,
    int? maxPhotosPerDay,
    String? selectedLanguage,
    int? totalApiTokens,
  }) {
    return SystemSettingsModel(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      autoApprovePhotos: autoApprovePhotos ?? this.autoApprovePhotos,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      defaultWelcomeCredits: defaultWelcomeCredits ?? this.defaultWelcomeCredits,
      maxPhotosPerDay: maxPhotosPerDay ?? this.maxPhotosPerDay,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      totalApiTokens: totalApiTokens ?? this.totalApiTokens,
    );
  }
}
