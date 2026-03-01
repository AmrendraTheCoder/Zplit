import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/group_provider.dart';
import '../providers/user_provider.dart';
import '../services/qr_share_service.dart';
import '../theme/app_colors.dart';

/// Camera-based QR scanner screen for joining groups via invite QR codes.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      const service = QrShareService();
      if (service.isValidInvite(rawValue)) {
        setState(() => _hasScanned = true);
        _controller.stop();
        _handleInvite(service.decodeGroupInvite(rawValue));
        return;
      }
    }
  }

  void _handleInvite(GroupInvite invite) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final groups = ref.read(groupsProvider);
    final alreadyMember = groups.any((g) => g.id == invite.groupId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.group_add_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Group Invite'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alreadyMember) ...[
              const Text('You are already a member of this group!'),
              const SizedBox(height: 8),
            ],
            _inviteRow('Group', invite.groupName),
            _inviteRow('Invited by', invite.inviterName),
            _inviteRow('Currency', invite.currency),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _hasScanned = false);
              _controller.start();
            },
            child: const Text('Cancel'),
          ),
          if (!alreadyMember)
            FilledButton(
              onPressed: () {
                // Add current user to the group
                ref
                    .read(groupsProvider.notifier)
                    .addMember(invite.groupId, user.id);
                Navigator.pop(ctx);
                context.pop(); // Go back from scanner

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Joined "${invite.groupName}"!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Join Group'),
            ),
          if (alreadyMember)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Go Back'),
            ),
        ],
      ),
    );
  }

  Widget _inviteRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Scan QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner area
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                // Scanner overlay
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: accent, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 36,
                      color: accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Point your camera at a Zplit QR code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ask a group member to show their QR code',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
