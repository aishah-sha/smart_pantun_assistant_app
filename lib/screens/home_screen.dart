import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import 'voice_classifier_screen.dart';
import 'browse_theme_screen.dart';
import 'search_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // FIX: Remove const - use regular list to allow proper state management
  final _screens = [
    const VoiceClassifierScreen(),
    BrowseThemeScreen(), // Remove const
    const SearchScreen(),
    const StatisticsScreen(),
  ];

  void _setTab(int i) => setState(() => _currentIndex = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX: Use IndexedStack with key to force rebuild when needed
      body: IndexedStack(
        index: _currentIndex,
        children: _screens.asMap().entries.map((entry) {
          // Force rebuild when switching tabs
          return KeyedSubtree(key: ValueKey(entry.key), child: entry.value);
        }).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.surfaceElevated, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.mic_rounded,
                  label: 'Suara',
                  index: 0,
                  current: _currentIndex,
                  onTap: _setTab,
                ),
                _NavItem(
                  icon: Icons.category_rounded,
                  label: 'Tema',
                  index: 1,
                  current: _currentIndex,
                  onTap: _setTab,
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  label: 'Cari',
                  index: 2,
                  current: _currentIndex,
                  onTap: _setTab,
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistik',
                  index: 3,
                  current: _currentIndex,
                  onTap: _setTab,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 11,
                color: active ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
