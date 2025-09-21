import 'dart:ui';

import 'package:cnn/common/button.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/features/Auth/abc.dart';
import 'package:cnn/features/Auth/controller/auth_controller_updated.dart';
import 'package:cnn/features/Auth/screens/sign_up_updated.dart';
import 'package:cnn/features/Auth/widgets/auth_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  static const routeName = '/login-page';
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Basic validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    // Get the auth controller from the provider
    final authController = ref.read(authControllerProvider);
    final value = await authController.signIn(email, password);

    if (value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful!')));
      // Clear the form
      emailController.clear();
      passwordController.clear();
      // Navigate to Home (named route) and remove previous routes
      if (mounted) {
        Navigator.of(context).pushNamed(Home.routeName);
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $value')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Themed gradient background
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
            ),
          ),
          // Subtle background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: Image.asset('assets/cow1.png', fit: BoxFit.cover),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lock_open,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back',
                                style: AppTheme.headingSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Sign in to continue',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Circular Avatar
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.accentGradient,
                      ),
                      child: const CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/cow1.png'),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Form card
                  Container(
                    decoration: AppTheme.cardDecoration,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthField(
                          hintText: "Enter your email",
                          controller: emailController,
                        ),
                        const SizedBox(height: 12),
                        AuthField(
                          hintText: "Password",
                          controller: passwordController,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Forgot Password",
                            style: AppTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Button(
                            onPressed: () => login(context),
                            text: 'Login',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Not a user? ", style: AppTheme.bodyMedium),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, SignUp.routeName);
                        },
                        child: Text(
                          "Signup",
                          style: AppTheme.labelLarge.copyWith(
                            color: AppTheme.accentTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
