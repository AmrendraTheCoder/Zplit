import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() {
  runApp(const ProviderScope(child: ZplitApp()));
}

/// The root widget of the Zplit app.
///
/// Wraps the entire app in a [ProviderScope] for Riverpod state
/// management, and uses [MaterialApp.router] with GoRouter for
/// declarative navigation.
class ZplitApp extends ConsumerWidget {
  const ZplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Zplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
