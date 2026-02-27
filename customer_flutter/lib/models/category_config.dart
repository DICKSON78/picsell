import 'package:flutter/material.dart';

/// Processing mode - determines which PhotoRoom API features to use
enum ProcessingMode {
  products,     // legacy (kept for backward compat, not shown in UI)
  food,         // Food — AI Beautify + Studio table surface + plate
  vehicles,     // legacy (kept for backward compat, not shown in UI)
  cakes,        // Bites & Cakes — AI Studio bakery branding backdrop
  cosmetics,    // Cosmetics & Beauty — fixed white marble luxury scene
  electronics,  // Electronics & Gadgets — dynamic clean bg (color-aware)
  fashion,      // Fashion & Clothing — fixed off-white seamless + wood hanger
  drinks,       // Drinks & Beverages — premium dark studio (Coca-Cola/Serengeti style)
}

/// Shadow types available in PhotoRoom API
enum ShadowType {
  soft,       // ai.soft - diffused shadow
  hard,       // ai.hard - sharp defined shadow
  floating,   // ai.floating - shadow beneath subject
}

/// Configuration for a processing category
class CategoryConfig {
  final ProcessingMode mode;
  final String nameSwahili;
  final String nameEnglish;
  final String descriptionSwahili;
  final String descriptionEnglish;
  final IconData icon;
  final Color iconColor;
  final double padding;

  // Products (solid color) specific
  final List<String> backgroundColors;

  // null = skip lighting entirely (safest for light/white products — no bleaching risk)
  // 'ai.preserve-hue-and-saturation' = relight while keeping colors (vehicles/food)
  final String? lightingMode;

  final ShadowType shadowType;

  // Food/Cakes specific
  final String? beautifyMode; // e.g. 'ai.food', 'ai.auto'

  // AI Studio background prompts (food, cakes, fashion, vehicles)
  final List<String> backgroundPrompts;

  const CategoryConfig({
    required this.mode,
    required this.nameSwahili,
    required this.nameEnglish,
    required this.descriptionSwahili,
    required this.descriptionEnglish,
    required this.icon,
    required this.iconColor,
    this.padding = 0.1,
    this.backgroundColors = const [],
    this.lightingMode,  // null by default = no relighting
    this.shadowType = ShadowType.soft,
    this.beautifyMode,
    this.backgroundPrompts = const [],
  });

  /// Get shadow mode string for PhotoRoom API
  String get shadowModeString {
    switch (shadowType) {
      case ShadowType.soft:     return 'ai.soft';
      case ShadowType.hard:     return 'ai.hard';
      case ShadowType.floating: return 'ai.floating';
    }
  }
}

/// Registry of all processing categories
class CategoryRegistry {
  // Counters — kept for API compatibility, effectively unused when single prompt
  static int _colorIndex           = 0;  // legacy products
  static int _foodPromptIndex      = 0;
  static int _cakesPromptIndex     = 0;
  static int _cosmeticsPromptIndex = 0;
  static int _fashionPromptIndex   = 0;
  static int _drinksPromptIndex    = 0;

  // ── LEGACY INTERNAL CONFIGS (not shown in UI) ──────────────────────────

  static const List<String> _legacyProductColors = ['F5F5F5', 'EEEEEE', 'F0EDE8'];

  // Single professional automotive studio prompt
  static const List<String> _legacyVehiclePrompts = [
    'professional automotive product photography, vehicle centered on a polished dark charcoal epoxy studio floor with a clean mirror-like reflection underneath, seamless very dark grey background, dramatic cool blue-toned rim lighting from both rear sides highlighting the vehicle body lines and curves, subtle low camera angle, no people, no scenery, no props, premium automotive advertising style, 85mm f/2.8, HD quality',
  ];

  // ── VISIBLE CATEGORIES (shown in UI) ───────────────────────────────────

  static final List<CategoryConfig> allCategories = [

    // ──────────────────────────────────────────────────────────
    // 1. BITES & CAKES — Fixed single professional patisserie scene.
    //    White Carrara marble surface, fresh white flowers, cream linen.
    //    Bright warm natural light from upper left. Never rotates.
    // ──────────────────────────────────────────────────────────
    const CategoryConfig(
      mode: ProcessingMode.cakes,
      nameSwahili: 'Keki na Vitafunio',
      nameEnglish: 'Bites & Cakes',
      descriptionSwahili: 'Keki, mikate na vitafunio',
      descriptionEnglish: 'Cakes, pastries & bites',
      icon: Icons.cake_rounded,
      iconColor: Color(0xFFE91E63),
      beautifyMode: 'ai.auto',
      padding: 0.05,
      backgroundPrompts: [
        // Single fixed professional patisserie scene — used by top bakery brands.
        // White Carrara marble + fresh white flowers + cream linen napkin.
        // Bright airy natural daylight, never dark.
        'professional patisserie food photography, 45-degree angle view, cake centered on a smooth clean white Carrara marble surface with subtle grey veining, two small fresh white flowers softly placed to the left of the cake, soft cream linen napkin folded at the lower right corner, bright warm natural daylight from the upper left, clean soft fill light from the right, bright airy elegant patisserie atmosphere, 85mm f/1.8, only the marble surface and flowers visible, no extra props, no clutter, HD quality',
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // 2. FOOD — Fixed single fine dining restaurant table scene.
    //    Michelin-star standard: large matte white porcelain plate,
    //    pressed white linen tablecloth, silver fork + knife,
    //    folded ivory linen napkin, soft 10-o'clock side backlight.
    //    Shallow depth of field. No walls, no room. Never rotates.
    // ──────────────────────────────────────────────────────────
    const CategoryConfig(
      mode: ProcessingMode.food,
      nameSwahili: 'Chakula',
      nameEnglish: 'Food',
      descriptionSwahili: 'Vyakula na menyu',
      descriptionEnglish: 'Food & menu items',
      icon: Icons.restaurant_rounded,
      iconColor: Color(0xFFFF5722),
      beautifyMode: 'ai.food',
      padding: 0.05,
      backgroundPrompts: [
        // Single fixed fine dining table scene — Michelin-star restaurant standard.
        // White linen tablecloth + silver cutlery + folded linen napkin.
        // Soft diffused side backlight from 10 o'clock, shallow depth of field.
        // No walls, no room interior, no other tables — just the table surface.
        'professional fine dining food photography, 45-degree angle shot, food served on a large matte white porcelain plate with a wide rim and deliberate negative space, plate centered on a pressed white linen tablecloth with subtle visible fabric weave texture, neatly folded ivory linen napkin placed to the left of the plate, polished silver dinner fork to the left of the plate, polished silver dinner knife to the right of the plate with blade facing inward, soft diffused natural light from the upper left at 10 o\'clock position creating gentle foreground shadows, shallow depth of field with slight bokeh on napkin and cutlery, fine dining Michelin restaurant table close-up, no walls, no room visible, no other tables, no background decor, clean and refined, 85mm f/2.8, HD quality',
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // 6. DRINKS & BEVERAGES — Fixed premium dark studio scene.
    //    Coca-Cola / Serengeti Premium style:
    //    Pure black seamless background, warm amber glow behind product,
    //    wet dark reflective acrylic surface, ice chunks, condensation.
    //    No bar, no table, no glass, no restaurant. Never rotates.
    // ──────────────────────────────────────────────────────────
    const CategoryConfig(
      mode: ProcessingMode.drinks,
      nameSwahili: 'Vinywaji',
      nameEnglish: 'Drinks & Beverages',
      descriptionSwahili: 'Soda, bia, juisi, maji na vinywaji',
      descriptionEnglish: 'Soda, beer, juice, water & beverages',
      icon: Icons.local_drink_rounded,
      iconColor: Color(0xFF0288D1),
      padding: 0.05,
      backgroundPrompts: [
        // Single fixed premium commercial beverage studio scene.
        // Coca-Cola / Serengeti Lager advertising standard:
        // Dark studio + amber glow + reflective surface + ice + condensation.
        'premium commercial beverage product photography, pure black seamless studio background with no texture or scenery, a soft warm amber and golden glow radiating from directly behind the product fading outward to pure black at the edges, wet highly polished dark acrylic surface beneath the product creating a clean mirror reflection below, scattered crystal clear acrylic ice chunks at the base of the product refracting light into bright prismatic highlights, fine water droplet condensation covering the product surface, soft studio rim lights on both sides defining the product silhouette against the dark background, no bar, no restaurant, no table, no glass, no food, no other objects, pure professional commercial advertising photography, photorealistic, 85mm f/2, HD quality',
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // 3. COSMETICS & BEAUTY — Fixed single professional luxury beauty scene.
    //    White marble surface, champagne silk drape, dried white flowers,
    //    smooth river stone. Soft warm window light from the left.
    //    Luxury prestige beauty brand style. Never rotates.
    // ──────────────────────────────────────────────────────────
    const CategoryConfig(
      mode: ProcessingMode.cosmetics,
      nameSwahili: 'Vipodozi na Urembo',
      nameEnglish: 'Cosmetics & Beauty',
      descriptionSwahili: 'Vipodozi, manukato na bidhaa za urembo',
      descriptionEnglish: 'Cosmetics, perfumes & beauty products',
      icon: Icons.spa_rounded,
      iconColor: Color(0xFFAB47BC),
      padding: 0.08,
      backgroundPrompts: [
        // Single fixed professional luxury beauty scene — prestige beauty brand standard.
        // White marble surface + champagne silk drape + dried white flowers + river stone.
        // Soft warm window light from left, warm champagne cream tones.
        'luxury beauty product photography, product perfectly centered on a polished white marble surface with fine light grey veining, soft champagne silk fabric gently draped behind the product, two small delicate dried white flowers and one smooth rounded river stone placed beside the product, soft warm natural window light diffused from the left side, subtle warm glow reflection on marble surface, warm champagne cream tones, 85mm f/1.8, high-end prestige beauty brand editorial photography, HD quality',
      ],
    ),

    // ──────────────────────────────────────────────────────────
    // 4. ELECTRONICS & GADGETS - Dynamic color-aware neutral background
    //    Background color is chosen automatically to complement
    //    the product's dominant color.
    //    Fallback colors: cool white, tech light grey, blue-grey.
    //    Shadow: soft — clean tech product look.
    // ──────────────────────────────────────────────────────────
    const CategoryConfig(
      mode: ProcessingMode.electronics,
      nameSwahili: 'Elektroniki na Gadgets',
      nameEnglish: 'Electronics & Gadgets',
      descriptionSwahili: 'Simu, laptop, gadgets na electronics',
      descriptionEnglish: 'Phones, laptops, gadgets & electronics',
      icon: Icons.devices_rounded,
      iconColor: Color(0xFF1976D2),
      shadowType: ShadowType.soft,
      padding: 0.08,
      // Fallback colors if color extraction fails
      backgroundColors: ['F0F2F5', 'ECF0F1', 'F5F5F5'],
    ),

    // ──────────────────────────────────────────────────────────
    // 5. FASHION & CLOTHING — Fixed single professional e-commerce scene.
    //    Garment hung on slim natural wood hanger, warm off-white
    //    seamless studio background, bright top-front studio lighting.
    //    Premium fashion e-commerce standard. Never rotates.
    // ──────────────────────────────────────────────────────────
    const CategoryConfig(
      mode: ProcessingMode.fashion,
      nameSwahili: 'Mavazi na Mitindo',
      nameEnglish: 'Fashion & Clothing',
      descriptionSwahili: 'Nguo, viatu, mifuko na mavazi',
      descriptionEnglish: 'Clothing, shoes, bags & fashion',
      icon: Icons.checkroom_rounded,
      iconColor: Color(0xFF00897B),
      padding: 0.05,
      backgroundPrompts: [
        // Single fixed professional fashion e-commerce scene — premium fashion brand standard.
        // Slim natural wood hanger + warm off-white seamless background.
        // Bright top-front studio lighting, clean and airy.
        'clothing apparel e-commerce photography, garment neatly hung on a slim natural wood hanger centered in frame, clean warm off-white seamless studio background, bright soft top-front studio lighting from above with gentle natural shadows, only the clothing and hanger visible, no model, no mannequin, no hands, no floor, no other objects, no props, clean minimal fashion studio composition, 85mm f/2, HD quality',
      ],
    ),
  ];

  // ── PUBLIC ACCESSORS ────────────────────────────────────────

  /// Get config by processing mode (returns first visible if not found)
  static CategoryConfig getConfig(ProcessingMode mode) {
    return allCategories.firstWhere(
      (config) => config.mode == mode,
      orElse: () => allCategories.first,
    );
  }

  // ── PROMPT / COLOR ROTATION ─────────────────────────────────

  /// Legacy product color rotation (fallback)
  static String getNextProductColor() {
    final color = _legacyProductColors[_colorIndex % _legacyProductColors.length];
    _colorIndex++;
    return color;
  }

  /// Legacy vehicle prompt (single fixed professional automotive scene)
  static String getNextVehiclePrompt() {
    final prompt = _legacyVehiclePrompts[_colorIndex % _legacyVehiclePrompts.length];
    _colorIndex++;
    return prompt;
  }

  /// Fixed food & drinks scene (single prompt — always returns same scene)
  static String getNextFoodPrompt() {
    final config = getConfig(ProcessingMode.food);
    final prompt = config.backgroundPrompts[_foodPromptIndex % config.backgroundPrompts.length];
    _foodPromptIndex++;
    return prompt;
  }

  /// Fixed patisserie scene for Bites & Cakes (single prompt — always returns same scene)
  static String getNextCakesPrompt() {
    final config = getConfig(ProcessingMode.cakes);
    final prompt = config.backgroundPrompts[_cakesPromptIndex % config.backgroundPrompts.length];
    _cakesPromptIndex++;
    return prompt;
  }

  /// Fixed luxury beauty scene for Cosmetics & Beauty (single prompt — always returns same scene)
  static String getNextCosmeticsPrompt() {
    final config = getConfig(ProcessingMode.cosmetics);
    final prompt = config.backgroundPrompts[_cosmeticsPromptIndex % config.backgroundPrompts.length];
    _cosmeticsPromptIndex++;
    return prompt;
  }

  /// Fixed fashion e-commerce scene (single prompt — always returns same scene)
  static String getNextFashionPrompt() {
    final config = getConfig(ProcessingMode.fashion);
    final prompt = config.backgroundPrompts[_fashionPromptIndex % config.backgroundPrompts.length];
    _fashionPromptIndex++;
    return prompt;
  }

  /// Fixed premium beverage studio scene (single prompt — always returns same scene)
  static String getNextDrinksPrompt() {
    final config = getConfig(ProcessingMode.drinks);
    final prompt = config.backgroundPrompts[_drinksPromptIndex % config.backgroundPrompts.length];
    _drinksPromptIndex++;
    return prompt;
  }

  /// Reset all rotation counters
  static void resetAllIndices() {
    _colorIndex           = 0;
    _foodPromptIndex      = 0;
    _cakesPromptIndex     = 0;
    _cosmeticsPromptIndex = 0;
    _fashionPromptIndex   = 0;
    _drinksPromptIndex    = 0;
  }
}
