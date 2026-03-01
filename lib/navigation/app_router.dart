import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/group_detail_screen.dart';
import '../screens/add_expense_screen.dart';
import '../screens/settle_up_picker_screen.dart';
import '../screens/settle_up_payment_screen.dart';
import '../screens/settle_up_success_screen.dart';
import '../screens/qr_share_screen.dart';
import '../screens/qr_scan_screen.dart';
import '../screens/group_stats_screen.dart';

/// GoRouter configuration for Zplit navigation.
///
/// Routes:
/// - `/onboarding` — Profile setup (shown if no user exists)
/// - `/home` — Dashboard with groups list
/// - `/create-group` — Create a new group
/// - `/group/:id` — Group detail (members, expenses, balances)
/// - `/group/:id/add-expense` — Add expense to a group
/// - `/group/:id/settle-up` — Settle Up member picker
/// - `/group/:id/settle-up/:memberId` — Payment method
/// - `/group/:id/settle-up/:memberId/success` — Settle Up success
final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: user == null ? '/onboarding' : '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-group',
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: 'qrScan',
        builder: (context, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/group/:id',
        name: 'groupDetail',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          return GroupDetailScreen(groupId: groupId);
        },
        routes: [
          GoRoute(
            path: 'add-expense',
            name: 'addExpense',
            builder: (context, state) {
              final groupId = state.pathParameters['id']!;
              return AddExpenseScreen(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'edit-expense/:expenseId',
            name: 'editExpense',
            builder: (context, state) {
              final groupId = state.pathParameters['id']!;
              final expenseId = state.pathParameters['expenseId']!;
              return AddExpenseScreen(groupId: groupId, expenseId: expenseId);
            },
          ),
          GoRoute(
            path: 'share',
            name: 'qrShare',
            builder: (context, state) {
              final groupId = state.pathParameters['id']!;
              return QrShareScreen(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'stats',
            name: 'groupStats',
            builder: (context, state) {
              final groupId = state.pathParameters['id']!;
              return GroupStatsScreen(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'settle-up',
            name: 'settleUpPicker',
            builder: (context, state) {
              final groupId = state.pathParameters['id']!;
              return SettleUpPickerScreen(groupId: groupId);
            },
            routes: [
              GoRoute(
                path: ':memberId',
                name: 'settleUpPayment',
                builder: (context, state) {
                  final groupId = state.pathParameters['id']!;
                  final memberId = state.pathParameters['memberId']!;
                  return SettleUpPaymentScreen(
                    groupId: groupId,
                    memberId: memberId,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'success',
                    name: 'settleUpSuccess',
                    builder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      final memberId = state.pathParameters['memberId']!;
                      return SettleUpSuccessScreen(
                        groupId: groupId,
                        memberId: memberId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isOnboarding = state.uri.path == '/onboarding';
      final hasUser = user != null;

      if (!hasUser && !isOnboarding) return '/onboarding';
      if (hasUser && isOnboarding) return '/home';
      return null;
    },
  );
});
