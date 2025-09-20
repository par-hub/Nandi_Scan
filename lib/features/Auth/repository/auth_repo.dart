import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepo = Provider((ref) => AuthRepo());

class AuthRepo {
  final supabase = Supabase.instance.client;

  Future<String?> signUp(
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        // Check for common Supabase errors
        if (response.session == null) {
          return "Email confirmation may be required. Please check your email.";
        }
        return "Signup failed. Please try again.";
      }

      return null; // success
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('User already registered')) {
        return "An account with this email already exists.";
      } else if (e.toString().contains('Password should be at least')) {
        return "Password must be at least 6 characters long.";
      } else if (e.toString().contains('Invalid email')) {
        return "Please enter a valid email address.";
      } else {
        return "Signup failed: ${e.toString()}";
      }
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return "Invalid email or password";
      }

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}
