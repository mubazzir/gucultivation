import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'services/persistence_service.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final db = PersistenceService();
  await db.init();

  runApp(ProviderScope(
    child: GuCultivationApp(hasProfile: db.hasProfile),
  ));
}

class GuCultivationApp extends StatelessWidget {
  final bool hasProfile;

  const GuCultivationApp({super.key, required this.hasProfile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gu Cultivation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: hasProfile ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
