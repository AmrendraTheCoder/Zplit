import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

/// Onboarding — Splitwise-inspired welcome + sign up.
///
/// Green circle header with ZPLIT logo, LOGIN / SIGN UP toggle,
/// form fields, and social login buttons.
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
  bool _isSignUp = true; // Toggle between Sign Up / Login view

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
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
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final username = _usernameController.text.trim();
    final finalUsername = username.isEmpty
        ? displayName.toLowerCase().replaceAll(' ', '_')
        : username;

    ref.read(currentUserProvider.notifier).setupUser(
          username: finalUsername,
          displayName: displayName,
          avatarColorIndex: _selectedColor,
          deviceId: const Uuid().v4(),
        );

    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: Column(
          children: [
            // ── Green Circle Header ───────────────────────
            _buildHeader(accent),

            // ── SIGN UP / LOGIN Toggle ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isSignUp = true),
                    child: Text(
                      'SIGN UP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            _isSignUp ? FontWeight.w800 : FontWeight.w500,
                        color: _isSignUp ? accent : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isSignUp = false),
                    child: Text(
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            !_isSignUp ? FontWeight.w800 : FontWeight.w500,
                        color:
                            !_isSignUp ? accent : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isSignUp
                    ? _buildSignUpForm(context)
                    : _buildLoginForm(context),
              ),
            ),

            // ── Social Login ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'G',
                    color: Colors.red,
                    bgColor: Colors.grey.shade100,
                  ),
                  const SizedBox(width: 16),
                  _socialButton(
                    icon: Icons.facebook_rounded,
                    label: '',
                    color: Colors.white,
                    bgColor: const Color(0xFF1877F2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.85)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 16),
          child: Column(
            children: [
              // Logo icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ZPLIT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formLabel('Name'),
          const SizedBox(height: 6),
          _formField(
            controller: _displayNameController,
            hint: 'Your display name',
          ),
          const SizedBox(height: 20),
          _formLabel('Username'),
          const SizedBox(height: 6),
          _formField(
            controller: _usernameController,
            hint: 'Optional username',
          ),
          const SizedBox(height: 20),
          _formLabel('Pick your color'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              AppColors.avatarColors.length,
              (index) => GestureDetector(
                onTap: () => setState(() => _selectedColor = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
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
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: _selectedColor == index
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Get Started',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formLabel('Username'),
          const SizedBox(height: 6),
          _formField(
            controller: _usernameController,
            hint: 'Your username',
          ),
          const SizedBox(height: 20),
          _formLabel('Display Name'),
          const SizedBox(height: 6),
          _formField(
            controller: _displayNameController,
            hint: 'Your display name',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Forgot your password?',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiaryLight,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _formLabel('Pick your color'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              AppColors.avatarColors.length,
              (index) => GestureDetector(
                onTap: () => setState(() => _selectedColor = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
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
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: _selectedColor == index
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: 120,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
