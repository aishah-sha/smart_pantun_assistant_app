import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_pantun_assistant_app/services/pantun_service.dart';
import '../app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Start loading your asset data asynchronously while the splash screen is visible
      await PantunService.instance.loadData();
    } catch (e) {
      debugPrint("Error loading pantun data: $e");
      // Handle your error case here if needed (e.g., missing asset file)
    }

    // 2. Introduce your structural delay before navigating to home screen
    await Future.delayed(const Duration(milliseconds: 2800));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, a, b) => const HomeScreen(),
          transitionsBuilder: (_, a, b, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppTheme.primaryLight, AppTheme.primary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            Text(
                  'Smart Pantun',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                )
                .animate(delay: 400.ms)
                .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(),
            const SizedBox(height: 8),
            Text(
                  'Penolong Pantun Pintar',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    color: AppTheme.primaryLight,
                    letterSpacing: 1.5,
                  ),
                )
                .animate(delay: 600.ms)
                .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(),
            const SizedBox(height: 12),
            Text(
              'Voice-to-Theme Classifier',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ).animate(delay: 700.ms).fadeIn(duration: 500.ms),
            const SizedBox(height: 60),
            Text(
              '5,644 Pantun • 6 Tema',
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
            ).animate(delay: 900.ms).fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
