import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'navigation/app_router.dart';

void main() {
  runApp(const ProviderScope(child: ZplitApp()));
}

/// The root widget of the Zplit app.
class ZplitApp extends ConsumerWidget {
  const ZplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Zplit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromMode(themeMode),
      routerConfig: router,
    );
  }
}
