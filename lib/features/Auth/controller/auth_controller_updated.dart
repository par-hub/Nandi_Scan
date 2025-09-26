import 'package:cnn/features/Auth/repository/auth_repo_updated.dart';
import 'package:cnn/common/auth_session_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final AuthRepo _authRepo;

  AuthController(this._authRepo);

  /// Check if user is automatically authenticated from stored session
  Future<bool> autoLogin() async {
    try {
      print('🔄 Attempting auto login...');
      
      // Initialize session service and check if user is authenticated
      final isAuthenticated = await AuthSessionService.initializeSession();
      
      if (isAuthenticated) {
        print('✅ Auto login successful');
        return true;
      }
      
      print('📭 Auto login failed - no valid session found');
      return false;
    } catch (e) {
      print('❌ Auto login error: $e');
      return false;
    }
  }

  /// Get current authenticated user
  User? getCurrentUser() {
    return AuthSessionService.getCurrentUser();
  }

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    return await AuthSessionService.isAuthenticated();
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    return await AuthSessionService.getCurrentUserId();
  }

  Future<String?> signUp(
    String email,
    String password,
    String confirmPassword,
    String name,
    String phone,
  ) async {
    final result = await _authRepo.signUp(
      email,
      password,
      confirmPassword,
      name,
      phone,
    );
    
    // If signup is successful, save the session
    if (result == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await AuthSessionService.saveSession(user);
      }
    }
    
    return result;
  }

  Future<String?> signIn(String email, String password) async {
    final result = await _authRepo.signIn(email, password);
    
    // If signin is successful, save the session
    if (result == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await AuthSessionService.saveSession(user);
      }
    }
    
    return result;
  }

  /// Sign out user and clear session
  Future<void> signOut() async {
    try {
      print('🚪 Signing out user...');
      await AuthSessionService.clearSession();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final repo = ref.watch(authRepo);
  return AuthController(repo);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final userProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});
