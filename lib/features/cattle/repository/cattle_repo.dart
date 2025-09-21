import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cattle_model.dart';

final cattleRepo = Provider((ref) => CattleRepo());

class CattleRepo {
  final supabase = Supabase.instance.client;

  /// Get all cattle owned by the current user
  Future<List<CattleModel>> getUserCattle() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return [];
      }

      final userId = user.id;
      print('Fetching cattle for user: $userId');

      final response = await supabase
          .from('user_defined_features')
          .select('''
            *,
            cow_buffalo!breed_id (
              breed
            )
          ''')
          .eq('user-id', userId)
          .order('specified_id', ascending: true);

      print('Database response: $response');

      return (response as List).map((item) {
        print('Processing item: $item');
        return CattleModel.fromJson(item);
      }).toList();
    } catch (e) {
      print('Error fetching user cattle: $e');
      return [];
    }
  }

  /// Get cattle count for current user
  Future<int> getUserCattleCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return 0;
      }

      final userId = user.id;
      
      final response = await supabase
          .from('user_defined_features')
          .select('specified_id')
          .eq('user-id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting cattle count: $e');
      return 0;
    }
  }

  /// Delete a cattle entry
  Future<String?> deleteCattle(int specifiedId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return "User not authenticated";
      }

      final userId = user.id;

      await supabase
          .from('user_defined_features')
          .delete()
          .eq('specified_id', specifiedId)
          .eq('user-id', userId);

      // Update User_details cattle count
      await _decrementUserCattleCount(userId);

      return null; // Success
    } catch (e) {
      return "Delete failed: ${e.toString()}";
    }
  }

  /// Update cattle information
  Future<String?> updateCattle(int specifiedId, {
    required double height,
    required String color,
    required double weight,
    required String gender,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return "User not authenticated";
      }

      final userId = user.id;

      await supabase
          .from('user_defined_features')
          .update({
            'height': height,
            'color': color,
            'weight': weight,
            'gender': gender,
          })
          .eq('specified_id', specifiedId)
          .eq('user-id', userId);

      return null; // Success
    } catch (e) {
      return "Update failed: ${e.toString()}";
    }
  }

  /// Private method to decrement cattle count in User_details table
  Future<void> _decrementUserCattleCount(String userId) async {
    try {
      final existingUser = await supabase
          .from('User_details')
          .select('user-id, cattles_owned')
          .eq('user-id', userId)
          .maybeSingle();

      if (existingUser != null) {
        final currentCount = existingUser['cattles_owned'] ?? 0;
        final newCount = currentCount > 0 ? currentCount - 1 : 0;
        await supabase
            .from('User_details')
            .update({'cattles_owned': newCount})
            .eq('user-id', userId);
        print('Decremented cattles_owned for user $userId: $newCount');
      } else {
        print('User $userId not found in User_details table when trying to decrement');
      }
    } catch (e) {
      print('Error updating User_details cattles_owned during deletion: $e');
    }
  }

  /// Test database connection
  Future<String> testConnection() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return "No authenticated user";
      }

      // Test user_defined_features table
      final response = await supabase
          .from('user_defined_features')
          .select('specified_id')
          .limit(1);

      return "✅ Connection successful! Found ${response.length} test records.";
    } catch (e) {
      return "❌ Connection failed: $e";
    }
  }
}