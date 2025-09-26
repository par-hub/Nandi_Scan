import 'package:cnn/features/profile/models/user_profile_model.dart';
import 'package:cnn/features/profile/repository/profile_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/features/Auth/controller/auth_controller_updated.dart';

// Profile state provider
final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final controller = ref.watch(profileControllerProvider);
  final user = ref.watch(userProvider);
  
  if (user == null) return null;
  
  return controller.getUserProfile(user.id);
});

// Profile controller provider
final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref.watch(profileRepoProvider));
});

class ProfileController {
  final ProfileRepo _profileRepo;

  ProfileController(this._profileRepo);

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Check if profile exists, if not create one
      final exists = await _profileRepo.userProfileExists(userId);
      UserProfile? profile;
      
      if (!exists) {
        // We'll need the email from somewhere, let's get it from auth
        final user = _profileRepo.supabase.auth.currentUser;
        final email = user?.email ?? '';
        profile = await _profileRepo.createUserProfile(userId, email);
      } else {
        profile = await _profileRepo.getUserProfile(userId);
      }

      return profile;
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  // Update user profile
  Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      return await _profileRepo.updateUserProfile(profile);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update specific fields
  Future<UserProfile?> updateProfileFields(String userId, {
    String? name,
    double? phone,
  }) async {
    try {
      final currentProfile = await getUserProfile(userId);
      if (currentProfile == null) return null;

      final updatedProfile = currentProfile.copyWith(
        name: name,
        phone: phone,
      );

      return await _profileRepo.updateUserProfile(updatedProfile);
    } catch (e) {
      throw Exception('Failed to update profile fields: $e');
    }
  }
}