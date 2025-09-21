import 'package:cnn/common/supabase_config.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/features/Auth/screens/splash_screen.dart';
import 'package:cnn/router.dart';
import 'package:cnn/common/auth_gate.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable debug paint and overflow indicators
  debugPaintSizeEnabled = false;

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  static String? routeName;

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nandi Scan',
      theme: AppTheme.lightTheme,
      onGenerateRoute: (settings) => generateRoute(settings),
      home: const SplashScreen(), // Start with splash screen instead of login
      builder: (context, child) {
        // Ensure debug paint is disabled
        debugPaintSizeEnabled = false;
        return child!;
      },
    );
  }
}
