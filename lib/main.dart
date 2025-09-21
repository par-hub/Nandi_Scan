import 'package:cnn/common/supabase_config.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/features/Auth/screens/login_page.dart';
import 'package:cnn/features/Auth/screens/sign_up_updated.dart';

import 'package:cnn/features/Specifation/screens/specification_with_controller.dart';
import 'package:cnn/features/cattle/screens/cattle_owned_screen.dart';
import 'package:cnn/features/registration/screen/reg_screen.dart';
import 'package:cnn/home.dart';
import 'package:cnn/router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  static var routeName;

  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
      onGenerateRoute: (settings) => generateRoute(settings),
      home: LoginPage(),
    );
  }
}
