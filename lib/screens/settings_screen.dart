import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

/// Settings screen — user profile, app info, and P2P identity.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile Card ─────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: user?.avatarColor ?? AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (user?.avatarColor ?? AppColors.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user?.username ?? 'user'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Edit profile
                  },
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── P2P Identity ────────────────────────
          Text('P2P Identity',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Share this ID with friends so they can find you during P2P sync.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fingerprint_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Device ID',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.deviceId ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: user?.deviceId ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device ID copied!'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('User ID',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user?.id ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── How P2P Sync Works ──────────────────
          Text('How Friend Sync Works',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _buildSyncStep(
            context,
            icon: Icons.wifi_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Nearby Discovery',
            subtitle:
                'When two Zplit devices are nearby, they discover each other via WiFi Direct or Bluetooth.',
          ),
          _buildSyncStep(
            context,
            icon: Icons.nfc_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Tap-to-Share',
            subtitle:
                'Tap phones together (NFC) to invite a friend to your group instantly.',
          ),
          _buildSyncStep(
            context,
            icon: Icons.qr_code_2_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'QR Code Invite',
            subtitle:
                'Generate a QR code containing your User ID + Device ID. Friends scan it to add you.',
          ),
          _buildSyncStep(
            context,
            icon: Icons.sync_rounded,
            iconColor: AppColors.primary,
            title: 'Auto-Sync Expenses',
            subtitle:
                'Once connected, expenses sync automatically via encrypted P2P transfer.',
          ),

          const SizedBox(height: 28),

          // ── App Info ────────────────────────────
          Text('About', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _buildInfoTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'Version',
            trailing: '1.0.0',
          ),
          _buildInfoTile(
            context,
            icon: Icons.code_rounded,
            title: 'Open Source',
            trailing: 'github.com/StabilityNexus/Zplit',
          ),
          _buildInfoTile(
            context,
            icon: Icons.security_rounded,
            title: 'Privacy',
            trailing: 'All data stays on your device',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSyncStep(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(trailing,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  )),
        ],
      ),
    );
  }
}
