import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/group_detail_screen.dart';
import '../screens/add_expense_screen.dart';

/// GoRouter configuration for Zplit navigation.
///
/// Routes:
/// - `/onboarding` — Profile setup (shown if no user exists)
/// - `/home` — Dashboard with groups list
/// - `/create-group` — Create a new group
/// - `/group/:id` — Group detail (members, expenses, balances)
/// - `/group/:id/add-expense` — Add expense to a group
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
