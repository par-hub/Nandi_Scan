import 'package:cnn/features/profile/models/user_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepoProvider = Provider<ProfileRepo>((ref) {
  return ProfileRepo();
});

class ProfileRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  ProfileRepo();

  // Get Supabase client (for controller access)
  SupabaseClient get supabase => _supabase;

  // Fetch user profile from User_details table
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('User_details')
          .select('*')
          .eq('user-id', userId)
          .maybeSingle();

      if (response == null) return null;

      // Get user email from auth
      final user = _supabase.auth.currentUser;
      final email = user?.email ?? '';

      // Create profile with email from auth
      final profileData = Map<String, dynamic>.from(response);
      profileData['email'] = email;

      return UserProfile.fromJson(profileData);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Update user profile in User_details table
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      final updateData = profile.toJson();
      // Remove email from update data as it's not stored in User_details
      updateData.remove('email');

      final response = await _supabase
          .from('User_details')
          .update(updateData)
          .eq('user-id', profile.id)
          .select()
          .single();

      // Get user email from auth for the updated profile
      final user = _supabase.auth.currentUser;
      final email = user?.email ?? profile.email;

      final updatedData = Map<String, dynamic>.from(response);
      updatedData['email'] = email;

      return UserProfile.fromJson(updatedData);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Create initial user profile in User_details table
  Future<UserProfile> createUserProfile(String userId, String email) async {
    try {
      final profileData = {
        'user-id': userId,
        'name': null,
        'phone': null,
        'cattles_owned': 0,
      };

      final response = await _supabase
          .from('User_details')
          .insert(profileData)
          .select()
          .single();

      final createdData = Map<String, dynamic>.from(response);
      createdData['email'] = email;

      return UserProfile.fromJson(createdData);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Check if user profile exists
  Future<bool> userProfileExists(String userId) async {
    try {
      final response = await _supabase
          .from('User_details')
          .select('user-id')
          .eq('user-id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}