import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

/// Onboarding screen — first screen the user sees.
///
/// Collects the user's display name and username, lets them pick an
/// avatar color. After completing, the user is redirected to Home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  int _selectedColor = 0;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleGetStarted() {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Auto-generate username from display name if not provided
    final finalUsername = username.isEmpty
        ? displayName.toLowerCase().replaceAll(' ', '_')
        : username;

    ref.read(currentUserProvider.notifier).setupUser(
          username: finalUsername,
          displayName: displayName,
          avatarColorIndex: _selectedColor,
          deviceId: const Uuid().v4(), // Simulated device ID for now
        );

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // ── Logo & Welcome ──────────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Z',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Welcome to Zplit',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Split expenses with friends,\nno servers needed.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                  ),

                  const SizedBox(height: 40),

                  // ── Display Name Input ──────────────────
                  Text(
                    'What should we call you?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _displayNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Display name (e.g., Amrendra)',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    onSubmitted: (_) => _handleGetStarted(),
                  ),

                  const SizedBox(height: 16),

                  // ── Username Input ──────────────────────
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Username (optional)',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Avatar Color Picker ─────────────────
                  Text(
                    'Pick your color',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(
                      AppColors.avatarColors.length,
                      (index) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.avatarColors[index],
                            shape: BoxShape.circle,
                            border: _selectedColor == index
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: _selectedColor == index
                                ? [
                                    BoxShadow(
                                      color: AppColors.avatarColors[index]
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: _selectedColor == index
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 22)
                              : null,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Get Started Button ──────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleGetStarted,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Get Started'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
