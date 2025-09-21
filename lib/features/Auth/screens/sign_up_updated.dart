import 'package:cnn/common/button.dart';
import 'package:cnn/common/user_storage.dart';
import 'package:cnn/common/user_data_debug_screen.dart';
import 'package:cnn/features/Auth/controller/auth_controller_updated.dart';
import 'package:cnn/features/Auth/widgets/auth_field.dart';
import 'package:flutter/material.dart';
import 'package:cnn/features/Auth/color_palet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUp extends ConsumerStatefulWidget {
  static const routeName = '/sign-up';
  const SignUp({super.key});

  @override
  ConsumerState<SignUp> createState() => _SignUpState();
}

class _SignUpState extends ConsumerState<SignUp> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Email validation function
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone validation function
  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  void signup(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    print('🔄 Starting signup process...');

    // Basic validation
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    if (!_isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
        ),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm your password')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    print('✅ Validation passed, setting loading state...');
    setState(() => _isLoading = true);

    try {
      print('🔄 Getting auth controller...');
      // Get the auth controller from the provider
      final authController = ref.read(authControllerProvider);
      
      print('🔄 Calling authController.signUp...');
      final value = await authController.signUp(
        email,
        password,
        confirmPassword,
        name,
        phone,
      );
      
      print('📧 Auth controller returned: $value');

      // Check if widget is still mounted before using context
      if (!mounted) return;

      if (value == null) {
        print('✅ Signup successful, getting user ID...');
        // Get the current user ID for display
        final userId = await UserStorage.getCurrentUserId();
        final filePath = UserStorage.getFilePath();
        
        print('📱 User ID: $userId');
        print('💾 File path: $filePath');
        
        // Check if widget is still mounted before using context
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Sign up successful!'),
                const SizedBox(height: 4),
                Text('📱 User ID: ${userId ?? 'N/A'}'),
                const SizedBox(height: 4),
                Text('💾 Saved to: ${filePath.split('\\').last}'),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        // Clear the form
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        nameController.clear();
        phoneController.clear();
      } else {
        print('❌ Signup failed: $value');
        // Check if widget is still mounted before using context
        if (!mounted) return;
        
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $value')));
      }
    } catch (e, stackTrace) {
      print('❌ Exception in signup: $e');
      print('📚 Stack trace: $stackTrace');
      
      // Check if widget is still mounted before using context
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${e.toString()}')),
      );
    } finally {
      print('🔄 Finishing signup, clearing loading state...');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: ColorPalet.backgroundColorAuth),
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/cow1.png"),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: ColorPalet.backgroundColorAuth,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("assets/cow1.png"),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: AuthField(
                          hintText: "Enter your full name",
                          controller: nameController,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: AuthField(
                          hintText: "Enter your phone number",
                          controller: phoneController,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: AuthField(
                          hintText: "Enter your email",
                          controller: emailController,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: AuthField(
                          hintText: "Password",
                          controller: passwordController,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: AuthField(
                          hintText: "Confirm Password",
                          controller: confirmPasswordController,
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: AbsorbPointer(
                          absorbing: _isLoading,
                          child: Button(
                            onPressed: () => signup(context),
                            text: _isLoading ? 'Signing Up...' : 'SignUP',
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Debug button to view JSON file
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserDataDebugScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report),
                        label: const Text('View User Data (Debug)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
