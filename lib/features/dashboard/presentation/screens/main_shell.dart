import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:amarnamovil/core/theme/app_theme.dart';
import 'package:amarnamovil/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:amarnamovil/features/jobs/presentation/screens/job_match_screen.dart';
import 'package:amarnamovil/features/dashboard/presentation/screens/home_screen.dart';
import 'package:amarnamovil/features/profile/presentation/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  final Map<String, dynamic> user;

  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(user: widget.user),
      JobMatchScreen(user: widget.user),
      HomeScreen(user: widget.user),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Only switch by tabs
        children: screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Inicio'),
      _NavItem(icon: Icons.psychology_outlined, label: 'JobMatch'),
      _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Entrenador'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Perfil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isActive ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              item.icon,
                              color: isActive ? AppTheme.primaryColor : Colors.grey.shade400,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? AppTheme.primaryColor : Colors.grey.shade400,
                            ),
                            child: Text(item.label),
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 3,
                            width: isActive ? 24 : 0,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
