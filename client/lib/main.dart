import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_heart/core/providers/current_user_notifier.dart';
import 'package:social_heart/core/theme/theme.dart';
import 'package:social_heart/features/auth/view/pages/login_page.dart';
import 'package:social_heart/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:social_heart/features/home/view/main_navigation.dart';
import 'package:social_heart/features/home/viewmodel/asset_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(authViewModelProvider.notifier).initSharedPreferences();
  await container.read(authViewModelProvider.notifier).getCurrentUser();
  await container.read(assetViewmodelProvider.notifier).getUserAsset();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserNotifierProvider);

    return MaterialApp(
      title: 'Social Heart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home:
          currentUser != null ? const MainNavigationPage() : const LoginPage(),
    );
  }
}
