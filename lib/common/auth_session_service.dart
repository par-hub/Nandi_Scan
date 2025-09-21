import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSessionService {
  static const String _isLoggedInKey = 'is_user_logged_in';
  static const String _userIdKey = 'current_user_id';
  static const String _sessionKey = 'supabase_session';
  
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize session on app startup
  static Future<bool> initializeSession() async {
    try {
      print('🔄 Initializing auth session...');
      
      // Check if Supabase has a current session
      final currentSession = _supabase.auth.currentSession;
      
      if (currentSession != null) {
        print('✅ Active Supabase session found for user: ${currentSession.user.id}');
        
        // Save session data to shared preferences
        await _saveSessionData(
          userId: currentSession.user.id,
          isLoggedIn: true,
        );
        
        return true;
      }
      
      // Check shared preferences for stored login state
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final storedUserId = prefs.getString(_userIdKey);
      
      if (isLoggedIn && storedUserId != null) {
        print('✅ Stored session found for user: $storedUserId');
        // Supabase will handle session restoration automatically
        return true;
      }
      
      print('📭 No active session found');
      return false;
    } catch (e) {
      print('❌ Error initializing session: $e');
      return false;
    }
  }

  /// Save authentication session data
  static Future<void> saveSession(User user) async {
    try {
      print('💾 Saving auth session for user: ${user.id}');
      
      await _saveSessionData(
        userId: user.id,
        isLoggedIn: true,
      );
      
      print('✅ Auth session saved successfully');
    } catch (e) {
      print('❌ Error saving auth session: $e');
      throw Exception('Failed to save authentication session');
    }
  }

  /// Clear authentication session
  static Future<void> clearSession() async {
    try {
      print('🗑️ Clearing auth session...');
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_sessionKey);
      
      print('✅ Auth session cleared successfully');
    } catch (e) {
      print('❌ Error clearing auth session: $e');
      throw Exception('Failed to clear authentication session');
    }
  }

  /// Check if user is currently authenticated
  static Future<bool> isAuthenticated() async {
    try {
      // First check Supabase current session
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        print('✅ User is authenticated via Supabase session');
        return true;
      }
      
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        print('✅ User is authenticated via stored session');
      } else {
        print('📭 User is not authenticated');
      }
      
      return isLoggedIn;
    } catch (e) {
      print('❌ Error checking authentication status: $e');
      return false;
    }
  }

  /// Get current user ID
  static Future<String?> getCurrentUserId() async {
    try {
      // First try to get from Supabase current session
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        return currentSession.user.id;
      }
      
      // Fallback to shared preferences
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Setup auth state listener
  static void setupAuthStateListener({
    required Function() onSignedIn,
    required Function() onSignedOut,
  }) {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      print('🔄 Auth state changed: $event');
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session?.user != null) {
            print('✅ User signed in: ${session!.user.id}');
            saveSession(session.user);
            onSignedIn();
          }
          break;
        case AuthChangeEvent.signedOut:
          print('📤 User signed out');
          _clearStoredSessionData();
          onSignedOut();
          break;
        case AuthChangeEvent.tokenRefreshed:
          print('🔄 Token refreshed');
          if (session?.user != null) {
            saveSession(session!.user);
          }
          break;
        default:
          break;
      }
    });
  }

  /// Private method to save session data to shared preferences
  static Future<void> _saveSessionData({
    required String userId,
    required bool isLoggedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setString(_userIdKey, userId);
  }

  /// Private method to clear stored session data
  static Future<void> _clearStoredSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_sessionKey);
  }

  /// Check if session is expired
  static bool isSessionExpired() {
    final currentSession = _supabase.auth.currentSession;
    if (currentSession == null) return true;
    
    final expiresAt = currentSession.expiresAt;
    if (expiresAt == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiresAt;
  }

  /// Attempt to refresh current session
  static Future<bool> refreshSession() async {
    try {
      print('🔄 Attempting to refresh session...');
      
      final response = await _supabase.auth.refreshSession();
      
      if (response.session != null && response.user != null) {
        print('✅ Session refreshed successfully');
        await saveSession(response.user!);
        return true;
      }
      
      print('❌ Failed to refresh session');
      return false;
    } catch (e) {
      print('❌ Error refreshing session: $e');
      return false;
    }
  }
}