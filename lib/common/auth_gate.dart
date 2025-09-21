import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cnn/home.dart';
import 'package:cnn/features/Auth/screens/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Already logged in
      return const Home();
    }

    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        // If we get a session in stream, show Home; otherwise, Login
        final s = snapshot.data?.session;
        if (s != null) {
          return const Home();
        }
        return const LoginPage();
      },
    );
  }
}
