import 'package:cnn/common/user_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepo = Provider((ref) => AuthRepo());

class AuthRepo {
  final supabase = Supabase.instance.client;

  Future<String?> signUp(
    String email,
    String password,
    String confirmPassword,
    String name,
    String phone,
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

      // Save additional user data to custom table
      if (response.user != null) {
        try {
          await _saveUserDetails(response.user!.id, name, phone, email);
          
          // Save user UUID to local CSV file
          try {
            print("📝 Attempting to save user UUID to CSV file...");
            await UserStorage.saveUserData(
              userId: response.user!.id,
              name: name,
              email: email,
              phone: phone,
            );
            print("✅ User UUID saved to CSV file successfully");
            
            // Verify the save by reading back the current user ID
            final savedUserId = await UserStorage.getCurrentUserId();
            if (savedUserId == response.user!.id) {
              print("✅ CSV save verified: User ID matches");
            } else {
              print("⚠️ CSV save verification failed: Expected ${response.user!.id}, got $savedUserId");
            }
          } catch (csvError) {
            print("❌ CSV save failed with error: $csvError");
            print("🔍 CSV error details: ${csvError.toString()}");
            // Don't fail the signup just because CSV save failed, but log it clearly
          }
        } catch (dbError) {
          print("❌ Database save failed: $dbError");
          
          // Check if this is a duplicate user error (user exists in Supabase auth but not in our custom table)
          if (dbError.toString().contains('duplicate key value violates unique constraint')) {
            print("⚠️ User already exists in database, but signup was successful");
            // Still save to CSV file for local storage
            try {
              print("📝 Attempting to save existing user UUID to CSV file...");
              await UserStorage.saveUserData(
                userId: response.user!.id,
                name: name,
                email: email,
                phone: phone,
              );
              print("✅ User UUID saved to CSV file (user already in database)");
              
              // Verify the save
              final savedUserId = await UserStorage.getCurrentUserId();
              if (savedUserId == response.user!.id) {
                print("✅ CSV save verified for existing user");
              } else {
                print("⚠️ CSV save verification failed for existing user");
              }
              return null; // Consider this a success since auth worked
            } catch (csvError) {
              print("❌ Failed to save UUID to CSV: $csvError");
              print("🔍 CSV error details: ${csvError.toString()}");
              return "Signup successful but failed to save user UUID locally.";
            }
          }
          
          // If database save fails for other reasons, we should fail the signup
          return "Failed to save user details. Please try again.";
        }
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

  Future<void> _saveUserDetails(
    String userId,
    String name,
    String phone,
    String email,
  ) async {
    try {
      print('🔄 Attempting to save user details to database...');
      print('📱 User ID: $userId');
      print('👤 Name: $name');
      print('📞 Phone: $phone');
      print('📧 Email: $email');
      
      final response = await supabase.from('User_details').insert({
        'user-id': userId,  // Database uses hyphen format as shown in error message
        'name': name,
        'phone': phone,  // Keep as string, phone is varchar in database
        // Note: email column doesn't exist in database, so we don't include it
      });

      print("✅ User details inserted successfully: $response");
    } catch (e) {
      print('❌ Error saving user details to database: $e');
      print('🔍 Full error details: ${e.toString()}');
      
      // Check if it's a database schema error
      if (e.toString().contains('invalid input syntax for type integer') || 
          e.toString().contains('user_id') ||
          e.toString().contains('column') ||
          e.toString().contains('does not exist')) {
        print('⚠️ SCHEMA MISMATCH: Database column/type error detected');
        print('💡 Check that User_details table has: user_id (uuid), name (text), phone (varchar)');
        throw Exception('Database schema mismatch: Please check table structure in Supabase.');
      }
      
      rethrow; // <-- important so you know it failed
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

      // Save user UUID to CSV for future use
      try {
        print("📝 Attempting to save user UUID to CSV on login...");
        await UserStorage.saveUserData(
          userId: response.user!.id,
          name: 'User', // Placeholder since we only store UUID
          email: email,
          phone: '0000000000', // Placeholder since we only store UUID
        );
        print("✅ User UUID saved to CSV on login");
        
        // Verify the save
        final savedUserId = await UserStorage.getCurrentUserId();
        if (savedUserId == response.user!.id) {
          print("✅ Login CSV save verified");
        } else {
          print("⚠️ Login CSV save verification failed");
        }
      } catch (e) {
        print("❌ Login successful but CSV save failed: $e");
        print("🔍 CSV error details: ${e.toString()}");
      }

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}
