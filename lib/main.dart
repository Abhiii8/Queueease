import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: QueueEaseApp(),
    ),
  );
}

class QueueEaseApp extends ConsumerWidget {
  const QueueEaseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'QueueEase',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light, // Enforce single UI
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
