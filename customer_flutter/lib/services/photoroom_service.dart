import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'local_storage_service.dart';
import '../models/category_config.dart';

class PhotoRoomService {
  // PhotoRoom v2/edit API
  static const String _apiUrl = 'https://image-api.photoroom.com/v2/edit';

  // PhotoRoom API key
  static const String _apiKey = 'sk_pr_default_d6e6e6b3c4a9724ee335edbbb5d6ecdcde82a41b';

  static String? _customApiKey;
  static void setApiKey(String key) => _customApiKey = key;
  static String get apiKey => _customApiKey ?? _apiKey;

  final LocalStorageService _localStorage = LocalStorageService();

  // Singleton pattern
  static final PhotoRoomService _instance = PhotoRoomService._internal();
  factory PhotoRoomService() => _instance;
  PhotoRoomService._internal();

  /// Common headers for all API requests
  Map<String, String> get _headers => {
    'Accept': 'image/jpeg, application/json',
    'x-api-key': apiKey,
  };

  /// Send request and handle response
  Future<Uint8List> _sendRequest(http.MultipartRequest request) async {
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? response.body);
      }
      return response.bodyBytes;
    } else {
      throw Exception('PhotoRoom API error: ${response.statusCode} - ${response.body}');
    }
  }

  // ============================================================
  // COLOR DETECTION — extracts dominant product color client-side
  // Uses the `image` package to sample pixels and find the most
  // common non-white, non-black color in the image.
  // ============================================================

  /// Extract dominant product color from [imageFile].
  /// Skips near-white (>230,230,230) and near-black (<25,25,25) pixels
  /// which are typically background or shadows. Returns null on failure.
  Future<Color?> _extractProductColor(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final Map<int, int> colorBuckets = {};
      // Sample step: aim for ~50×50 grid over the image
      final int step = math.max(1, math.min(image.width, image.height) ~/ 50);

      for (int y = 0; y < image.height; y += step) {
        for (int x = 0; x < image.width; x += step) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // Skip near-white (likely background) and near-black pixels
          if (r > 230 && g > 230 && b > 230) continue;
          if (r < 25 && g < 25 && b < 25) continue;

          // Quantize to 32-step buckets to cluster similar colors
          final qr = (r ~/ 32) * 32;
          final qg = (g ~/ 32) * 32;
          final qb = (b ~/ 32) * 32;
          final key = (qr << 16) | (qg << 8) | qb;
          colorBuckets[key] = (colorBuckets[key] ?? 0) + 1;
        }
      }

      if (colorBuckets.isEmpty) return null;

      // Get the most frequent color bucket
      final dominant = colorBuckets.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final r = (dominant >> 16) & 0xFF;
      final g = (dominant >> 8) & 0xFF;
      final b = dominant & 0xFF;
      return Color.fromARGB(255, r, g, b);
    } catch (_) {
      return null;
    }
  }

  /// Pick the best neutral background hex color to complement [productColor].
  /// Returns a hex string without '#' suitable for PhotoRoom background.color.
  String _pickNeutralBackground(Color productColor) {
    final hsl = HSLColor.fromColor(productColor);
    final hue        = hsl.hue;
    final lightness  = hsl.lightness;
    final saturation = hsl.saturation;

    // Very dark product (e.g. black bag) → warm light ivory
    if (lightness < 0.20) return 'F5F2EE';

    // Very light product (e.g. white shirt) → medium cool grey
    if (lightness > 0.80) return 'E2E5E8';

    // Low saturation (grey/neutral product) → warm linen
    if (saturation < 0.12) return 'F0EDE8';

    // Warm hues (red/orange/yellow: 0–60° and 300–360°) → cool grey background
    if (hue <= 60 || hue >= 300) return 'ECF0F1';

    // Cool hues (blue/cyan/purple: 180–300°) → warm ivory background
    if (hue >= 180 && hue < 300) return 'FAF7F4';

    // Green hues (60–180°) → neutral warm grey
    return 'F5F5F2';
  }


  // ============================================================
  // 1. PRODUCTS (legacy) - Solid Color + Shadow
  // ============================================================

  Future<Uint8List> processProducts(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    // Use dynamic color detection, fall back to static rotation
    String color;
    final dominant = await _extractProductColor(imageFile);
    if (dominant != null) {
      color = _pickNeutralBackground(dominant);
    } else {
      color = CategoryRegistry.getNextProductColor();
    }

    request.fields['background.color'] = color;
    request.fields['shadow.mode'] = config.shadowModeString;
    if (config.lightingMode != null) {
      request.fields['lighting.mode'] = config.lightingMode!;
    }
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // 2. FOOD & DRINKS - AI Beautify (food) + AI Studio table + plate
  // ============================================================

  Future<Uint8List> processFood(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-ai-background-model-version'] = 'background-studio-beta-2025-03-17';
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    request.fields['beautify.mode'] = config.beautifyMode ?? 'ai.food';
    request.fields['background.prompt'] = CategoryRegistry.getNextFoodPrompt();
    // ai.never: prompt used exactly as written — ensures the precise fine dining
    // table props (white linen, silver cutlery, napkin) appear consistently every time.
    request.fields['background.expandPrompt.mode'] = 'ai.never';
    // Re-light the food for warm diffused window-light quality while preserving
    // the dish's natural colours. Safe alongside ai.never (no conflict).
    request.fields['lighting.mode'] = 'ai.preserve-hue-and-saturation';
    // NOTE: negativePrompt intentionally omitted — has no effect on Studio model.
    // NOTE: referenceBox intentionally omitted — default behavior crops the subject
    // and auto-centers it in the canvas, ensuring products are always centered
    // regardless of how the user positioned them in the original photo.
    request.fields['background.scaling'] = 'fill';
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // 3. BITES & CAKES - AI Beautify (auto) + AI Studio bakery backdrop
  // ============================================================

  Future<Uint8List> processCakes(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-ai-background-model-version'] = 'background-studio-beta-2025-03-17';
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    request.fields['beautify.mode'] = config.beautifyMode ?? 'ai.auto';
    request.fields['background.prompt'] = CategoryRegistry.getNextCakesPrompt();
    // ai.never: prompt used exactly as written — ensures the precise patisserie
    // scene (white marble, flowers, linen) appears consistently every time.
    request.fields['background.expandPrompt.mode'] = 'ai.never';
    // Re-light the cake for bright airy natural daylight quality while preserving
    // icing and decoration colors. Safe alongside ai.never (no conflict).
    request.fields['lighting.mode'] = 'ai.preserve-hue-and-saturation';
    // NOTE: negativePrompt intentionally omitted — has no effect on Studio model.
    // NOTE: referenceBox intentionally omitted — auto-centers the subject.
    request.fields['background.scaling'] = 'fill';
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // 4. COSMETICS & BEAUTY - AI Studio luxury branding backdrop
  //    Rotates through 5 premium advertising environments:
  //    Classic brown marble surface, overhead top-down spotlight,
  //    product perfectly centered, no props, no extra objects.
  // ============================================================

  Future<Uint8List> processCosmetics(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-ai-background-model-version'] = 'background-studio-beta-2025-03-17';
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    // expandPrompt.mode=ai.never: prompt used exactly as written every time —
    // same consistent background, no random AI additions or variations.
    request.fields['background.prompt'] = CategoryRegistry.getNextCosmeticsPrompt();
    request.fields['background.expandPrompt.mode'] = 'ai.never';

    // Re-light the product for warm overhead studio illumination while
    // preserving cosmetic colour accuracy (lip shades, skin tones, etc.).
    // Safe to combine with ai.never — conflict only occurs with ai.auto.
    request.fields['lighting.mode'] = 'ai.preserve-hue-and-saturation';

    // NOTE: shadow.mode intentionally omitted — the Studio AI background
    // already renders contextually correct shadows. Combining shadow.mode
    // with an AI-generated background creates double/unnatural shadows.
    // NOTE: referenceBox intentionally omitted — auto-centers the subject.

    request.fields['background.scaling'] = 'fill';
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // 5. ELECTRONICS & GADGETS - Color-aware clean neutral background
  //    Detects the product's dominant color, picks the best
  //    contrasting tech-clean background automatically.
  // ============================================================

  Future<Uint8List> processElectronics(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    // Color-aware background selection
    String bgColor;
    final dominant = await _extractProductColor(imageFile);
    if (dominant != null) {
      bgColor = _pickNeutralBackground(dominant);
    } else {
      final colors = config.backgroundColors;
      bgColor = colors.isNotEmpty
          ? colors[DateTime.now().millisecondsSinceEpoch % colors.length]
          : 'F0F2F5';
    }

    request.fields['background.color'] = bgColor;
    request.fields['shadow.mode'] = config.shadowModeString; // ai.soft
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // 6. DRINKS & BEVERAGES - Premium dark studio (Coca-Cola/Serengeti style)
  //    Pure black seamless background, warm amber glow behind product,
  //    wet dark reflective acrylic surface, ice chunks, condensation.
  //    No bar, no table, no glass. Same scene every time.
  // ============================================================

  Future<Uint8List> processDrinks(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-ai-background-model-version'] = 'background-studio-beta-2025-03-17';
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    // Fixed premium commercial beverage studio scene.
    // Dark background + amber glow + reflective surface + ice + condensation.
    // ai.never: prompt used exactly as written — no random additions, consistent every time.
    request.fields['background.prompt'] = CategoryRegistry.getNextDrinksPrompt();
    request.fields['background.expandPrompt.mode'] = 'ai.never';

    // Re-light the bottle/can for clean studio illumination while preserving
    // label colour accuracy. Safe alongside ai.never (no conflict).
    request.fields['lighting.mode'] = 'ai.preserve-hue-and-saturation';
    // NOTE: referenceBox intentionally omitted — auto-centers the subject.
    request.fields['background.scaling'] = 'fill';
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // 7. FASHION & CLOTHING - Color-aware clean neutral background
  //    Same approach as Electronics: detects clothing dominant color,
  //    picks the best complementing white-grey neutral automatically.
  //    Fallback: soft light grey.
  // ============================================================

  Future<Uint8List> processFashion(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    // Color-aware background — same logic as electronics.
    // Detects dominant clothing color, picks neutral white-grey that complements it.
    String bgColor;
    final dominant = await _extractProductColor(imageFile);
    if (dominant != null) {
      bgColor = _pickNeutralBackground(dominant);
    } else {
      bgColor = 'F2F2F2'; // fallback: soft light grey
    }

    request.fields['background.color'] = bgColor;
    request.fields['shadow.mode'] = config.shadowModeString; // ai.soft
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // 7. VEHICLES (legacy) - AI Studio Background (Tanzanian Scenes)
  // ============================================================

  Future<Uint8List> processVehicles(File imageFile, CategoryConfig config) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.headers.addAll(_headers);
    request.headers['pr-ai-background-model-version'] = 'background-studio-beta-2025-03-17';
    request.headers['pr-hd-background-removal'] = 'auto';

    request.files.add(await http.MultipartFile.fromPath('imageFile', imageFile.path));

    request.fields['background.prompt'] = CategoryRegistry.getNextVehiclePrompt();
    request.fields['background.expandPrompt.mode'] = 'ai.never';
    request.fields['background.negativePrompt'] =
        'CGI, digital art, illustration, painting, cartoon, 3D render, '
        'unrealistic, fake, artificial, overexposed sky, oversaturated colors, '
        'HDR, too perfect, studio backdrop, plain gradient background, '
        'lens flare, fog, fantasy, surreal, overprocessed, plastic look, '
        'flat lighting, uniform background, stock photo watermark';
    request.fields['background.scaling'] = 'fill';
    if (config.lightingMode != null) {
      request.fields['lighting.mode'] = config.lightingMode!;
    }
    request.fields['padding'] = config.padding.toString();
    request.fields['outputSize'] = '2000x2000';
    request.fields['export.format'] = 'jpeg';
    return _sendRequest(request);
  }

  // ============================================================
  // MAIN ENTRY POINT - Process by mode
  // ============================================================

  Future<SmartProcessingResult> processByMode(File imageFile, ProcessingMode mode) async {
    final config = CategoryRegistry.getConfig(mode);

    Uint8List processedBytes;

    switch (mode) {
      case ProcessingMode.products:
        processedBytes = await processProducts(imageFile, config);
        break;
      case ProcessingMode.food:
        processedBytes = await processFood(imageFile, config);
        break;
      case ProcessingMode.vehicles:
        processedBytes = await processVehicles(imageFile, config);
        break;
      case ProcessingMode.cakes:
        processedBytes = await processCakes(imageFile, config);
        break;
      case ProcessingMode.cosmetics:
        processedBytes = await processCosmetics(imageFile, config);
        break;
      case ProcessingMode.electronics:
        processedBytes = await processElectronics(imageFile, config);
        break;
      case ProcessingMode.fashion:
        processedBytes = await processFashion(imageFile, config);
        break;
      case ProcessingMode.drinks:
        processedBytes = await processDrinks(imageFile, config);
        break;
    }

    // Save to local storage
    final savedFile = await _localStorage.saveProcessedImage(processedBytes);

    return SmartProcessingResult(
      processedFile: savedFile,
      brandingSuggestions: generateBrandingSuggestions(),
      processingMode: config.nameEnglish,
    );
  }

  // ============================================================
  // LOCAL STORAGE METHODS
  // ============================================================

  Future<List<File>> getRecentImages({int limit = 10}) async {
    return await _localStorage.getRecentImages(limit: limit);
  }

  Future<List<File>> getAllProcessedImages() async {
    return await _localStorage.getProcessedImages();
  }

  Future<bool> deleteImage(File imageFile) async {
    return await _localStorage.deleteImage(imageFile);
  }

  Future<bool> hasProcessedImages() async {
    return await _localStorage.hasImages();
  }

  Future<int> getImageCount() async {
    return await _localStorage.getImageCount();
  }

  // ============================================================
  // BRANDING SUGGESTIONS
  // ============================================================

  List<BrandingSuggestion> generateBrandingSuggestions() {
    return [
      BrandingSuggestion(text: 'Bei Nafuu - Ubora wa Juu!', textEn: 'Affordable Price - Top Quality!', category: 'price'),
      BrandingSuggestion(text: 'Mpya Kabisa!', textEn: 'Brand New!', category: 'condition'),
      BrandingSuggestion(text: 'Piga Simu Sasa!', textEn: 'Call Now!', category: 'cta'),
      BrandingSuggestion(text: 'Delivery Bure!', textEn: 'Free Delivery!', category: 'offer'),
      BrandingSuggestion(text: 'Bei ya Mwisho', textEn: 'Final Price', category: 'price'),
      BrandingSuggestion(text: 'Inauzwa Haraka!', textEn: 'Selling Fast!', category: 'urgency'),
      BrandingSuggestion(text: 'Original 100%', textEn: '100% Original', category: 'quality'),
      BrandingSuggestion(text: 'Guarantee Ipo!', textEn: 'Guaranteed!', category: 'trust'),
      BrandingSuggestion(text: 'Kipande Kimoja Tu!', textEn: 'Only One Piece Left!', category: 'urgency'),
      BrandingSuggestion(text: 'Bei Punguzo!', textEn: 'Discounted Price!', category: 'offer'),
    ];
  }

  List<BrandingSuggestion> getBrandingSuggestionsForCategory(String category) {
    return generateBrandingSuggestions().where((s) => s.category == category).toList();
  }

  List<String> getBrandingCategories() {
    return ['price', 'condition', 'cta', 'offer', 'urgency', 'quality', 'trust'];
  }
}

/// Result from processing
class SmartProcessingResult {
  final File processedFile;
  final List<BrandingSuggestion> brandingSuggestions;
  final String processingMode;

  SmartProcessingResult({
    required this.processedFile,
    required this.brandingSuggestions,
    required this.processingMode,
  });
}

/// Branding text suggestion
class BrandingSuggestion {
  final String text;
  final String textEn;
  final String category;

  BrandingSuggestion({
    required this.text,
    required this.textEn,
    required this.category,
  });
}
