import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, swahili }

class LocalizationProvider extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;
  static const String _languageKey = 'app_language';

  LocalizationProvider() {
    // Default to English as requested
    _currentLanguage = AppLanguage.english;
    _loadLanguagePreference();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isSwahili => false; // Enforce English
  bool get isEnglish => true;

  // Load language from SharedPreferences
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null) {
        _currentLanguage = savedLanguage == 'swahili'
            ? AppLanguage.swahili
            : AppLanguage.english;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language preference: $e');
    }
  }

  // Save language to SharedPreferences
  Future<void> _saveLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _languageKey,
        _currentLanguage == AppLanguage.swahili ? 'swahili' : 'english'
      );
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      _saveLanguagePreference();
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == AppLanguage.english
        ? AppLanguage.swahili
        : AppLanguage.english;
    _saveLanguagePreference();
    notifyListeners();
  }

  // Get translated string
  String tr(String key) {
    return AppStrings.get(key, _currentLanguage);
  }
}

class AppStrings {
  static const Map<String, Map<AppLanguage, String>> _strings = {
    // Common
    'app_name': {
      AppLanguage.english: 'PicSell',
      AppLanguage.swahili: 'PicSell',
    },
    'continue_btn': {
      AppLanguage.english: 'Continue',
      AppLanguage.swahili: 'Endelea',
    },
    'cancel': {
      AppLanguage.english: 'Cancel',
      AppLanguage.swahili: 'Ghairi',
    },
    'confirm': {
      AppLanguage.english: 'Confirm',
      AppLanguage.swahili: 'Thibitisha',
    },
    'save': {
      AppLanguage.english: 'Save',
      AppLanguage.swahili: 'Hifadhi',
    },
    'delete': {
      AppLanguage.english: 'Delete',
      AppLanguage.swahili: 'Futa',
    },
    'edit': {
      AppLanguage.english: 'Edit',
      AppLanguage.swahili: 'Hariri',
    },
    'loading': {
      AppLanguage.english: 'Loading...',
      AppLanguage.swahili: 'Inapakia...',
    },
    'error': {
      AppLanguage.english: 'Error',
      AppLanguage.swahili: 'Hitilafu',
    },
    'success': {
      AppLanguage.english: 'Success',
      AppLanguage.swahili: 'Imefanikiwa',
    },

    // Auth
    'welcome_back': {
      AppLanguage.english: 'Welcome Back',
      AppLanguage.swahili: 'Karibu Tena',
    },
    'sign_in_continue': {
      AppLanguage.english: 'Sign in to continue',
      AppLanguage.swahili: 'Ingia ili kuendelea',
    },
    'email_address': {
      AppLanguage.english: 'Email Address',
      AppLanguage.swahili: 'Anwani ya Barua Pepe',
    },
    'enter_email': {
      AppLanguage.english: 'Enter your email',
      AppLanguage.swahili: 'Ingiza barua pepe yako',
    },
    'password': {
      AppLanguage.english: 'Password',
      AppLanguage.swahili: 'Nenosiri',
    },
    'enter_password': {
      AppLanguage.english: 'Enter your password',
      AppLanguage.swahili: 'Ingiza nenosiri lako',
    },
    'forgot_password': {
      AppLanguage.english: 'Forgot Password?',
      AppLanguage.swahili: 'Umesahau Nenosiri?',
    },
    'sign_in': {
      AppLanguage.english: 'Sign In',
      AppLanguage.swahili: 'Ingia',
    },
    'sign_in_google': {
      AppLanguage.english: 'Sign in with Google',
      AppLanguage.swahili: 'Ingia na Google',
    },
    'no_account': {
      AppLanguage.english: "Don't have an account?",
      AppLanguage.swahili: 'Huna akaunti?',
    },
    'sign_up': {
      AppLanguage.english: 'Sign Up',
      AppLanguage.swahili: 'Jisajili',
    },
    'create_account': {
      AppLanguage.english: 'Create Account',
      AppLanguage.swahili: 'Fungua Akaunti',
    },
    'register_picsell': {
      AppLanguage.english: 'Register for PicSell',
      AppLanguage.swahili: 'Jisajili kwa PicSell',
    },
    'full_name': {
      AppLanguage.english: 'Full Name',
      AppLanguage.swahili: 'Jina Kamili',
    },
    'enter_name': {
      AppLanguage.english: 'Enter your name',
      AppLanguage.swahili: 'Ingiza jina lako',
    },
    'phone_number': {
      AppLanguage.english: 'Phone Number',
      AppLanguage.swahili: 'Namba ya Simu',
    },
    'enter_phone': {
      AppLanguage.english: 'Enter phone number',
      AppLanguage.swahili: 'Ingiza namba ya simu',
    },
    'have_account': {
      AppLanguage.english: 'Already have an account?',
      AppLanguage.swahili: 'Tayari una akaunti?',
    },
    'terms_agreement': {
      AppLanguage.english: 'By continuing, you agree to our Terms of Service and Privacy Policy',
      AppLanguage.swahili: 'Kwa kuendelea, unakubali Masharti ya Huduma na Sera ya Faragha',
    },

    // OTP
    'verify_otp': {
      AppLanguage.english: 'Verify OTP',
      AppLanguage.swahili: 'Thibitisha OTP',
    },
    'verify_number': {
      AppLanguage.english: 'Verify your number',
      AppLanguage.swahili: 'Thibitisha namba yako',
    },
    'otp_sent': {
      AppLanguage.english: 'We sent OTP to',
      AppLanguage.swahili: 'Tumetuma OTP kwa',
    },
    'enter_verification': {
      AppLanguage.english: 'Enter verification code',
      AppLanguage.swahili: 'Ingiza nambari ya uthibitisho',
    },
    'resend_otp_in': {
      AppLanguage.english: 'Resend OTP in',
      AppLanguage.swahili: 'Tuma OTP tena baada ya',
    },
    'resend_otp': {
      AppLanguage.english: 'Resend OTP',
      AppLanguage.swahili: 'Tuma OTP Tena',
    },
    'verify_register': {
      AppLanguage.english: 'Verify & Register',
      AppLanguage.swahili: 'Thibitisha na Sajili',
    },

    // Home
    'welcome': {
      AppLanguage.english: 'Welcome',
      AppLanguage.swahili: 'Karibu',
    },
    'credits': {
      AppLanguage.english: 'Credits',
      AppLanguage.swahili: 'Krediti',
    },
    'available_credits': {
      AppLanguage.english: 'Available Credits',
      AppLanguage.swahili: 'Krediti Zilizopo',
    },
    'buy_credits': {
      AppLanguage.english: 'Buy Credits',
      AppLanguage.swahili: 'Nunua Krediti',
    },
    'take_photo': {
      AppLanguage.english: 'Take Photo',
      AppLanguage.swahili: 'Piga Picha',
    },
    'upload_photo': {
      AppLanguage.english: 'Upload Photo',
      AppLanguage.swahili: 'Pakia Picha',
    },
    'recent_photos': {
      AppLanguage.english: 'Recent Photos',
      AppLanguage.swahili: 'Picha za Hivi Karibuni',
    },
    'view_all': {
      AppLanguage.english: 'View All',
      AppLanguage.swahili: 'Tazama Zote',
    },
    'capture_camera': {
      AppLanguage.english: 'Capture with camera',
      AppLanguage.swahili: 'Piga picha na kamera',
    },
    'select_gallery': {
      AppLanguage.english: 'Select from gallery',
      AppLanguage.swahili: 'Chagua kutoka galari',
    },

    // Account
    'account_settings': {
      AppLanguage.english: 'Account Settings',
      AppLanguage.swahili: 'Mipangilio ya Akaunti',
    },
    'edit_profile': {
      AppLanguage.english: 'Edit Profile',
      AppLanguage.swahili: 'Hariri Wasifu',
    },
    'update_info': {
      AppLanguage.english: 'Update your personal information',
      AppLanguage.swahili: 'Sasisha taarifa zako binafsi',
    },
    'my_portfolio': {
      AppLanguage.english: 'My Portfolio',
      AppLanguage.swahili: 'Mkusanyiko Wangu',
    },
    'manage_gallery': {
      AppLanguage.english: 'Manage your photo gallery',
      AppLanguage.swahili: 'Simamia galari yako ya picha',
    },
    'payment_methods': {
      AppLanguage.english: 'Payment Methods',
      AppLanguage.swahili: 'Njia za Malipo',
    },
    'add_remove_payment': {
      AppLanguage.english: 'Add or remove payment methods',
      AppLanguage.swahili: 'Ongeza au ondoa njia za malipo',
    },
    'notifications': {
      AppLanguage.english: 'Notifications',
      AppLanguage.swahili: 'Arifa',
    },
    'manage_notifications': {
      AppLanguage.english: 'Manage notification preferences',
      AppLanguage.swahili: 'Simamia mapendeleo ya arifa',
    },
    'privacy_security': {
      AppLanguage.english: 'Privacy & Security',
      AppLanguage.swahili: 'Faragha na Usalama',
    },
    'control_privacy': {
      AppLanguage.english: 'Control your privacy settings',
      AppLanguage.swahili: 'Simamia mipangilio ya faragha',
    },
    'language': {
      AppLanguage.english: 'Language',
      AppLanguage.swahili: 'Lugha',
    },
    'help_support': {
      AppLanguage.english: 'Help & Support',
      AppLanguage.swahili: 'Msaada na Usaidizi',
    },
    'get_help': {
      AppLanguage.english: 'Get help with your account',
      AppLanguage.swahili: 'Pata msaada wa akaunti yako',
    },
    'sign_out': {
      AppLanguage.english: 'Sign Out',
      AppLanguage.swahili: 'Toka',
    },
    'sign_out_account': {
      AppLanguage.english: 'Sign out of your account',
      AppLanguage.swahili: 'Toka kwenye akaunti yako',
    },
    'sign_out_confirm': {
      AppLanguage.english: 'Are you sure you want to sign out?',
      AppLanguage.swahili: 'Una uhakika unataka kutoka?',
    },

    // Credits
    'credit_balance': {
      AppLanguage.english: 'Credit Balance',
      AppLanguage.swahili: 'Salio la Krediti',
    },
    'purchase_credits': {
      AppLanguage.english: 'Purchase Credits',
      AppLanguage.swahili: 'Nunua Krediti',
    },
    'credit_packages': {
      AppLanguage.english: 'Credit Packages',
      AppLanguage.swahili: 'Vifurushi vya Krediti',
    },
    'popular': {
      AppLanguage.english: 'Popular',
      AppLanguage.swahili: 'Maarufu',
    },
    'best_value': {
      AppLanguage.english: 'Best Value',
      AppLanguage.swahili: 'Thamani Bora',
    },

    // History
    'history': {
      AppLanguage.english: 'History',
      AppLanguage.swahili: 'Historia',
    },
    'photo_history': {
      AppLanguage.english: 'Photo History',
      AppLanguage.swahili: 'Historia ya Picha',
    },
    'all_processed': {
      AppLanguage.english: 'All your processed photos',
      AppLanguage.swahili: 'Picha zako zote zilizochakatwa',
    },
    'filter': {
      AppLanguage.english: 'Filter',
      AppLanguage.swahili: 'Chuja',
    },
    'sort': {
      AppLanguage.english: 'Sort',
      AppLanguage.swahili: 'Panga',
    },
    'date_range': {
      AppLanguage.english: 'Date Range',
      AppLanguage.swahili: 'Kipindi cha Tarehe',
    },
    'status': {
      AppLanguage.english: 'Status',
      AppLanguage.swahili: 'Hali',
    },
    'completed': {
      AppLanguage.english: 'Completed',
      AppLanguage.swahili: 'Imekamilika',
    },
    'pending': {
      AppLanguage.english: 'Pending',
      AppLanguage.swahili: 'Inasubiri',
    },
    'processing': {
      AppLanguage.english: 'Processing',
      AppLanguage.swahili: 'Inachakatwa',
    },
    'failed': {
      AppLanguage.english: 'Failed',
      AppLanguage.swahili: 'Imeshindwa',
    },

    // Gallery
    'gallery': {
      AppLanguage.english: 'Gallery',
      AppLanguage.swahili: 'Galari',
    },
    'my_photos': {
      AppLanguage.english: 'My Photos',
      AppLanguage.swahili: 'Picha Zangu',
    },
    'all_saved_photos': {
      AppLanguage.english: 'All your saved photos',
      AppLanguage.swahili: 'Picha zako zote zilizohifadhiwa',
    },
    'download': {
      AppLanguage.english: 'Download',
      AppLanguage.swahili: 'Pakua',
    },
    'share': {
      AppLanguage.english: 'Share',
      AppLanguage.swahili: 'Shiriki',
    },

    // Welcome bonus
    'welcome_bonus': {
      AppLanguage.english: 'Welcome Bonus!',
      AppLanguage.swahili: 'Zawadi ya Karibu!',
    },
    'congratulations': {
      AppLanguage.english: 'Congratulations!',
      AppLanguage.swahili: 'Hongera!',
    },
    'received_credits': {
      AppLanguage.english: 'You received',
      AppLanguage.swahili: 'Umepokea',
    },
    'free_credits': {
      AppLanguage.english: 'free credits!',
      AppLanguage.swahili: 'krediti za bure!',
    },
    'use_credits_process': {
      AppLanguage.english: 'Use these credits to process your photos',
      AppLanguage.swahili: 'Tumia krediti hizi kuchakata picha zako',
    },
    'thank_you': {
      AppLanguage.english: 'Thank you!',
      AppLanguage.swahili: 'Asante!',
    },

    // Registration success
    'registration_success': {
      AppLanguage.english: 'Registration Successful',
      AppLanguage.swahili: 'Usajili Umefanikiwa',
    },
    'registered_successfully': {
      AppLanguage.english: 'You have registered successfully',
      AppLanguage.swahili: 'Umejisajili kikamilifu',
    },
    'got_free_credits': {
      AppLanguage.english: 'You got 5 free credits!',
      AppLanguage.swahili: 'Umepata krediti 5 za bure!',
    },

    // Country picker
    'select_country': {
      AppLanguage.english: 'Select Country',
      AppLanguage.swahili: 'Chagua Nchi',
    },
    'search_country': {
      AppLanguage.english: 'Search country...',
      AppLanguage.swahili: 'Tafuta nchi...',
    },

    // Validation errors
    'enter_email_error': {
      AppLanguage.english: 'Please enter your email',
      AppLanguage.swahili: 'Tafadhali ingiza barua pepe yako',
    },
    'valid_email_error': {
      AppLanguage.english: 'Please enter a valid email',
      AppLanguage.swahili: 'Tafadhali ingiza barua pepe sahihi',
    },
    'enter_password_error': {
      AppLanguage.english: 'Please enter your password',
      AppLanguage.swahili: 'Tafadhali ingiza nenosiri lako',
    },
    'password_length_error': {
      AppLanguage.english: 'Password must be at least 6 characters',
      AppLanguage.swahili: 'Nenosiri lazima liwe angalau herufi 6',
    },
    'enter_name_error': {
      AppLanguage.english: 'Please enter your name',
      AppLanguage.swahili: 'Tafadhali ingiza jina lako',
    },
    'full_name_error': {
      AppLanguage.english: 'Enter full name (first and last name)',
      AppLanguage.swahili: 'Ingiza jina kamili (jina la kwanza na la mwisho)',
    },
    'enter_phone_error': {
      AppLanguage.english: 'Please enter phone number',
      AppLanguage.swahili: 'Tafadhali ingiza namba ya simu',
    },
    'invalid_phone_error': {
      AppLanguage.english: 'Invalid phone number',
      AppLanguage.swahili: 'Namba ya simu si sahihi',
    },
    'enter_otp_error': {
      AppLanguage.english: 'Please enter complete OTP',
      AppLanguage.swahili: 'Tafadhali ingiza OTP kamili',
    },

    // Category selection
    'choose_category': {
      AppLanguage.english: 'Choose Product Category',
      AppLanguage.swahili: 'Chagua Aina ya Bidhaa',
    },
    'select_product_type': {
      AppLanguage.english: 'Select your product type for best results',
      AppLanguage.swahili: 'Chagua aina ya bidhaa yako kwa matokeo bora',
    },
    'oils_perfumes': {
      AppLanguage.english: 'Oils & Perfumes',
      AppLanguage.swahili: 'Mafuta & Perfumes',
    },
    'fashion_shoes': {
      AppLanguage.english: 'Fashion & Shoes',
      AppLanguage.swahili: 'Nguo & Viatu',
    },
    'electronics': {
      AppLanguage.english: 'Electronics',
      AppLanguage.swahili: 'Elektroniki',
    },
    'food': {
      AppLanguage.english: 'Food',
      AppLanguage.swahili: 'Chakula',
    },
    'automotive': {
      AppLanguage.english: 'Automotive',
      AppLanguage.swahili: 'Magari',
    },
    'furniture': {
      AppLanguage.english: 'Furniture',
      AppLanguage.swahili: 'Samani',
    },
    'beauty_cosmetics': {
      AppLanguage.english: 'Beauty & Cosmetics',
      AppLanguage.swahili: 'Urembo',
    },
    'jewelry': {
      AppLanguage.english: 'Jewelry',
      AppLanguage.swahili: 'Vito',
    },
    'general_products': {
      AppLanguage.english: 'General',
      AppLanguage.swahili: 'Kawaida',
    },
    'processing_ai': {
      AppLanguage.english: 'Processing with AI...',
      AppLanguage.swahili: 'Inachakata na AI...',
    },
    'enhancing_ai': {
      AppLanguage.english: 'Processing...',
      AppLanguage.swahili: 'Inachakata...',
    },
  };

  static String get(String key, AppLanguage language) {
    final translation = _strings[key];
    if (translation == null) return key;
    return translation[language] ?? translation[AppLanguage.english] ?? key;
  }
}
