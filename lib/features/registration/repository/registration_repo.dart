import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cattle_registration_model.dart';
import '../../../common/supabase_config.dart';

final registrationRepo = Provider((ref) => RegistrationRepo());

class RegistrationRepo {
  final supabase = Supabase.instance.client;

  /// Test Supabase connection
  Future<String> testConnection() async {
    try {
      print('=== TESTING SUPABASE CONNECTION ===');
      print('URL: ${SupabaseConfig.supabaseUrl}');
      print('Attempting to connect...');
      
      // Step 1: Test basic connection with simple select
      print('Step 1: Testing basic connection...');
      final basicTest = await supabase
          .from('cow_buffalo')
          .select('id')
          .limit(1);
          
      print('Step 1 successful! Response: $basicTest');
      
      // Step 2: Test if we can get all columns
      print('Step 2: Testing full column access...');
      final fullTest = await supabase
          .from('cow_buffalo')
          .select('id, breed, gender, count')
          .limit(5);
          
      print('Step 2 successful! Found ${fullTest.length} records');
      
      // Step 3: Test user_defined_features table
      print('Step 3: Testing user_defined_features table...');
      final userFeaturesTest = await supabase
          .from('user_defined_features')
          .select('specified_id')
          .limit(1);
          
      print('Step 3 successful! user_defined_features table exists with ${userFeaturesTest.length} records');
      
      return """
✅ CONNECTION SUCCESS

URL: ${SupabaseConfig.supabaseUrl}

Test Results:
✅ Basic connection: PASSED
✅ cow_buffalo table: PASSED (${fullTest.length} records found)
✅ user_defined_features table: PASSED

Sample data from cow_buffalo:
${fullTest.take(3).map((e) => '- ${e['breed']} (${e['gender']})').join('\n')}

All systems ready for cattle registration!
""";
    } catch (e) {
      print('=== CONNECTION ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Full Error: ${e.toString()}');
      
      // Detailed error analysis
      String errorAnalysis = "";
      String solution = "";
      
      if (e.toString().contains('cow_buffalo') && e.toString().contains('does not exist')) {
        errorAnalysis = "❌ cow_buffalo table does not exist";
        solution = "Run the database_setup.sql script in your Supabase SQL editor";
      } else if (e.toString().contains('user_defined_features') && e.toString().contains('does not exist')) {
        errorAnalysis = "❌ user_defined_features table does not exist";
        solution = "Run the database_setup.sql script in your Supabase SQL editor";
      } else if (e.toString().contains('permission') || e.toString().contains('policy')) {
        errorAnalysis = "❌ Permission/Policy error";
        solution = "Check Row Level Security policies in Supabase dashboard";
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorAnalysis = "❌ Network connectivity issue";
        solution = "Check internet connection and Supabase service status";
      } else {
        errorAnalysis = "❌ Unknown error";
        solution = "Check Supabase URL and API key";
      }
      
      String errorDetails = """
❌ CONNECTION FAILED

$errorAnalysis

Error Type: ${e.runtimeType}
Error Message: $e

URL: ${SupabaseConfig.supabaseUrl}

SOLUTION: $solution

Full Technical Details:
${e.toString()}

Next Steps:
1. $solution
2. If tables don't exist, run database_setup.sql
3. Check Supabase dashboard for any issues
4. Verify internet connection

Copy this entire message for debugging.
""";
      
      return errorDetails;
    }
  }

  /// Get breed information from Cow/Buffalo table
  Future<BreedInfo?> getBreedInfo(String breed, String gender) async {
    try {
      final response = await supabase
          .from('cow_buffalo') // Assuming table name is cow_buffalo
          .select('id, breed, gender, count')
          .eq('breed', breed)
          .eq('gender', gender)
          .single();

      return BreedInfo.fromJson(response);
    } catch (e) {
      print('Error getting breed info: $e');
      return null;
    }
  }

  /// Check if breed exists in the database
  Future<List<BreedInfo>> getAllBreeds() async {
    try {
      final response = await supabase
          .from('cow_buffalo')
          .select('id, breed, gender, count');

      return (response as List)
          .map((item) => BreedInfo.fromJson(item))
          .toList();
    } catch (e) {
      print('Error getting all breeds: $e');
      // Return empty list if database is not available
      // This allows the UI to fall back to hardcoded breeds
      return [];
    }
  }

  /// Register cattle with user-defined features
  Future<String?> registerCattle(CattleRegistrationModel cattle) async {
    int userId = 0;  // Changed to int
    Map<String, dynamic> userDefinedFeatures = {};
    
    try {
      // Get current user
      final user = supabase.auth.currentUser;
      
      // For testing purposes, create a temporary user ID if no user is authenticated
      if (user == null) {
        // Use a test user ID for development
        userId = 12345;  // Test integer user ID
        print('No authenticated user, using test user ID: $userId');
      } else {
        // Convert UUID to integer using hashCode
        userId = user.id.hashCode.abs();  // Convert UUID to positive integer
        print('Registering cattle for authenticated user: ${user.id} (mapped to ID: $userId)');
      }
      
      // Try to get the breed_id from cow_buffalo table
      final breedInfo = await getBreedInfo(cattle.breed, cattle.gender);
      print('Breed info: $breedInfo'); // Debug
      
      // Create entry in user_defined_features table
      userDefinedFeatures = {
        'height': cattle.height,
        'color': cattle.color,
        'weight': cattle.weight,
        'user_id': userId,
        'breed_id': breedInfo?.id, // This can be null if table doesn't exist
        'gender': cattle.gender,
      };

      print('Inserting data: $userDefinedFeatures'); // Debug

      await supabase
          .from('user_defined_features')
          .insert(userDefinedFeatures);

      print('Data inserted successfully'); // Debug

      // Update the count in cow_buffalo table if breed info exists
      if (breedInfo != null) {
        await supabase
            .from('cow_buffalo')
            .update({'count': breedInfo.count + 1})
            .eq('id', breedInfo.id);
        print('Count updated for breed'); // Debug
      }

      // Increment cattles_owned in User_details table
      await _incrementUserCattleCount(userId);
      print('User cattle count incremented'); // Debug

      return null; // Success
    } catch (e) {
      print('=== REGISTRATION ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Full Error: ${e.toString()}');
      print('User ID: $userId');
      print('Data attempted: $userDefinedFeatures');
      
      // Create detailed error message
      String errorType = "Unknown Error";
      String solution = "Contact support with this error message.";
      
      if (e.toString().contains('duplicate key')) {
        errorType = "Duplicate Entry";
        solution = "This cattle registration already exists.";
      } else if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        errorType = "Database Table Missing";
        solution = "Database tables not set up. Run the SQL script from database_setup.sql";
      } else if (e.toString().contains('authentication')) {
        errorType = "Authentication Error";
        solution = "Please sign in first or check API permissions.";
      } else if (e.toString().contains('parse')) {
        errorType = "Data Parse Error";
        solution = "Check input data format. Ensure height and weight are valid numbers.";
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorType = "Network Error";
        solution = "Check internet connection and try again.";
      }
      
      String detailedError = """
❌ REGISTRATION FAILED

Error Type: $errorType
Solution: $solution

Technical Details:
- Error Class: ${e.runtimeType}
- Error Message: $e
- User ID: $userId
- Supabase URL: ${SupabaseConfig.supabaseUrl}

Data Attempted:
$userDefinedFeatures

Copy this entire message for debugging.
""";
      
      return detailedError;
    }
  }

  /// Get user's registered cattle
  Future<List<CattleRegistrationModel>> getUserCattle() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      // Convert UUID to integer using same method as registration
      final userId = user.id.hashCode.abs();

      final response = await supabase
          .from('user_defined_features')
          .select('''
            *,
            cow_buffalo!breed_id (
              breed
            )
          ''')
          .eq('user_id', userId);  // Use integer user ID

      return (response as List).map((item) {
        return CattleRegistrationModel(
          breed: item['cow_buffalo']['breed'] ?? '',
          gender: item['gender'] ?? '',
          height: (item['height'] ?? 0.0).toDouble(),
          color: item['color'] ?? '',
          weight: (item['weight'] ?? 0.0).toDouble(),
          userId: item['user_id'],
          breedId: item['breed_id'],
        );
      }).toList();
    } catch (e) {
      print('Error getting user cattle: $e');
      return [];
    }
  }

  /// Update cattle information
  Future<String?> updateCattle(int specifiedId, CattleRegistrationModel cattle) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return "User not authenticated";
      }

      // Convert UUID to integer using same method as registration
      final userId = user.id.hashCode.abs();

      await supabase
          .from('user_defined_features')
          .update({
            'height': cattle.height,
            'color': cattle.color,
            'weight': cattle.weight,
            'gender': cattle.gender,
          })
          .eq('specified_id', specifiedId)
          .eq('user_id', userId);  // Use integer user ID

      return null; // Success
    } catch (e) {
      return "Update failed: ${e.toString()}";
    }
  }

  /// Delete cattle registration
  Future<String?> deleteCattle(int specifiedId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return "User not authenticated";
      }

      // Convert UUID to integer using same method as registration
      final userId = user.id.hashCode.abs();

      await supabase
          .from('user_defined_features')
          .delete()
          .eq('specified_id', specifiedId)
          .eq('user_id', userId);  // Use integer user ID

      // Decrement cattles_owned in User_details table
      await _decrementUserCattleCount(userId);
      print('User cattle count decremented'); // Debug

      return null; // Success
    } catch (e) {
      return "Delete failed: ${e.toString()}";
    }
  }

  /// Private method to increment cattle count in User_details table
  Future<void> _incrementUserCattleCount(int userId) async {
    try {
      // First, check if user exists in User_details table
      final existingUser = await supabase
          .from('User_details')
          .select('user_id, cattles_owned')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingUser != null) {
        // User exists, increment cattles_owned
        final currentCount = existingUser['cattles_owned'] ?? 0;
        await supabase
            .from('User_details')
            .update({'cattles_owned': currentCount + 1})
            .eq('user_id', userId);
        print('Incremented cattles_owned for user $userId: ${currentCount + 1}');
      } else {
        // User doesn't exist, create new entry with cattles_owned = 1
        await supabase
            .from('User_details')
            .insert({
              'user_id': userId,
              'cattles_owned': 1,
              // Add other default values if needed based on your table schema
            });
        print('Created new user entry with user_id $userId and cattles_owned = 1');
      }
    } catch (e) {
      print('Error updating User_details cattles_owned: $e');
      // Don't throw error - cattle registration should still succeed even if this fails
    }
  }

  /// Private method to decrement cattle count in User_details table
  Future<void> _decrementUserCattleCount(int userId) async {
    try {
      // Check if user exists in User_details table
      final existingUser = await supabase
          .from('User_details')
          .select('user_id, cattles_owned')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingUser != null) {
        // User exists, decrement cattles_owned (but don't go below 0)
        final currentCount = existingUser['cattles_owned'] ?? 0;
        final newCount = currentCount > 0 ? currentCount - 1 : 0;
        await supabase
            .from('User_details')
            .update({'cattles_owned': newCount})
            .eq('user_id', userId);
        print('Decremented cattles_owned for user $userId: $newCount');
      } else {
        print('User $userId not found in User_details table when trying to decrement');
      }
    } catch (e) {
      print('Error updating User_details cattles_owned during deletion: $e');
      // Don't throw error - cattle deletion should still succeed even if this fails
    }
  }
}