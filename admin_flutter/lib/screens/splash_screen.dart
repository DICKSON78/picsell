import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeInController;
  late AnimationController _fadeOutController;
  late AnimationController _glowController;
  late Animation<double> _logoFadeIn;
  late Animation<double> _textFadeIn;
  late Animation<double> _fadeOut;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _logoFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _textFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeInController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _fadeInController.forward();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.initialize();
    } catch (_) {
      // If initialization fails, fall through to login
    }

    await Future.delayed(const Duration(milliseconds: 2800));
    if (mounted) {
      await _fadeOutController.forward();

      if (!mounted) return;

      if (auth.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else if (auth.isPendingApproval) {
        Navigator.of(context).pushReplacementNamed('/pending-approval');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _fadeOutController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeInController, _fadeOutController, _glowController]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Opacity(
              opacity: _fadeOutController.isAnimating || _fadeOutController.isCompleted
                  ? _fadeOut.value
                  : 1.0,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with glow ring
                    Opacity(
                      opacity: _logoFadeIn.value,
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Animated glow ring
                            Container(
                              width: 150,
                              height: 150,
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
                              width: 138,
                              height: 138,
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
                              width: 124,
                              height: 124,
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
                      ),
                    ),

                    const SizedBox(height: 40),
                    // Text with fade animation
                    Opacity(
                      opacity: _textFadeIn.value,
                      child: Column(
                        children: [
                          Text(
                            'PicSell',
                            style: GoogleFonts.poppins(
                              color: AppTheme.whiteColor,
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage It, Grow It',
                            style: GoogleFonts.poppins(
                              color: AppTheme.whiteColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
