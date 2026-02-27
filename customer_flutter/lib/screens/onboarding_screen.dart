import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Professional Photography',
      description:
          'Capture stunning photos with our advanced camera technology and professional-grade editing tools',
      illustration: 'camera',
      accentColor: AppTheme.primaryColor,
    ),
    OnboardingPage(
      title: 'PicSell Studio',
      description:
          'Transform your photos with intelligent background removal and automatic enhancement',
      illustration: 'ai',
      accentColor: AppTheme.accent,
    ),
    OnboardingPage(
      title: 'Share Your Work',
      description:
          'Connect with clients and showcase your portfolio to grow your photography business',
      illustration: 'share',
      accentColor: AppTheme.accentPink,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextButton(
                    onPressed: () => _completeOnboarding(),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        color: AppTheme.whiteColor.withAlpha(204),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return OnboardingPageWidget(page: _pages[index]);
                  },
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    // Page indicators with cyan accent
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppTheme.accent
                                : AppTheme.whiteColor.withAlpha(128),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Continue button
                    PrimaryButton(
                      text: _currentPage < _pages.length - 1
                          ? 'Continue'
                          : 'Get Started',
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completeOnboarding() {
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String illustration;
  final Color accentColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
    required this.accentColor,
  });
}

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration with glow
          Expanded(
            flex: 3,
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated glow ring
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha((60 + (_glowAnimation.value * 80)).toInt()),
                                blurRadius: 20 + (_glowAnimation.value * 20),
                                spreadRadius: 2 + (_glowAnimation.value * 6),
                              ),
                            ],
                          ),
                        ),
                        // Glow outline ring
                        Container(
                          width: 186,
                          height: 186,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha((80 + (_glowAnimation.value * 120)).toInt()),
                              width: 2.5,
                            ),
                          ),
                        ),
                        // Logo circle (tight)
                        Container(
                          width: 168,
                          height: 168,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Text content
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.page.title,
                    style: GoogleFonts.poppins(
                      color: AppTheme.whiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.page.description,
                    style: GoogleFonts.poppins(
                      color: AppTheme.whiteColor.withAlpha(204),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
