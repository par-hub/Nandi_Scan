import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const String _csvFileName = 'user_data.csv';
  static const String _storageKey = 'user_data_csv';

  /// Save user UUID to CSV file (only UUID, nothing else)
  static Future<void> saveUserData({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      if (kIsWeb) {
        // For web, save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageKey, userId);
        print('✅ User UUID saved to browser storage: $userId');
      } else {
        // For mobile/desktop, save to CSV file
        final file = File(_csvFileName);
        
        // Check if user already exists in CSV to prevent duplicates
        bool userExists = false;
        if (await file.exists()) {
          final csvContent = await file.readAsString();
          final lines = csvContent.split('\n');
          for (String line in lines) {
            if (line.trim() == userId) {
              userExists = true;
              print('⚠️ User UUID already exists in CSV: $userId');
              break;
            }
          }
        }
        
        if (!userExists) {
          // Check if file exists to decide whether to add header
          bool fileExists = await file.exists();
          String csvContent = '';
          
          if (!fileExists) {
            // Add CSV header for new file
            csvContent = 'user_id\n';
            print('📝 Creating new CSV file with header');
          }
          
          // Add user UUID only
          csvContent += '$userId\n';
          
          // Append to file (or create if doesn't exist)
          await file.writeAsString(csvContent, mode: FileMode.append);
          print('✅ User UUID saved to CSV file: ${file.absolute.path}');
          print('📱 User ID: $userId');
          
          // Verify the file was written correctly
          if (await file.exists()) {
            final fileSize = await file.length();
            final fileContent = await file.readAsString();
            final lineCount = fileContent.split('\n').where((line) => line.trim().isNotEmpty).length;
            print('📄 CSV file size: $fileSize bytes');
            print('📊 Total entries in CSV: ${lineCount - 1} (excluding header)'); // -1 for header
          }
        } else {
          print('ℹ️ User UUID already exists in CSV, skipping duplicate entry');
        }
      }
    } catch (e) {
      print('❌ Error saving user UUID to CSV: $e');
      print('🔍 Full error details: ${e.toString()}');
      throw Exception('Failed to save user UUID to CSV: $e');
    }
  }

  /// Load user UUID from CSV file
  static Future<String?> getCurrentUserId() async {
    try {
      if (kIsWeb) {
        // For web, load from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString(_storageKey);
        if (userId == null) {
          print('📂 User UUID not found in browser storage');
          return null;
        }
        print('✅ User UUID loaded from browser storage: $userId');
        return userId;
      } else {
        // For mobile/desktop, read from CSV file
        final file = File(_csvFileName);
        if (!await file.exists()) {
          print('📂 User CSV file does not exist');
          return null;
        }
        
        final csvContent = await file.readAsString();
        final lines = csvContent.split('\n');
        
        // Get the last line with data (skip header and empty lines)
        for (int i = lines.length - 1; i >= 1; i--) {
          if (lines[i].trim().isNotEmpty) {
            final userId = lines[i].trim();
            print('✅ User UUID loaded from CSV file: $userId');
            return userId;
          }
        }
        
        print('📂 No user UUID found in CSV file');
        return null;
      }
    } catch (e) {
      print('❌ Error loading user UUID from CSV: $e');
      return null;
    }
  }

  /// Check if user UUID exists
  static Future<bool> isUserLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }

  /// Clear user UUID (logout)
  static Future<void> clearUserData() async {
    try {
      if (kIsWeb) {
        // Use SharedPreferences for web
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
        print('✅ User UUID cleared from browser storage');
      } else {
        // Use file system for mobile/desktop
        final file = File(_csvFileName);
        if (await file.exists()) {
          await file.delete();
          print('✅ CSV file deleted');
        }
      }
    } catch (e) {
      print('❌ Error clearing user UUID: $e');
    }
  }

  /// Get file path for debugging
  static String getFilePath() {
    if (kIsWeb) {
      return 'Browser Storage (localStorage) - CSV: $_storageKey';
    } else {
      final csvFile = File(_csvFileName);
      return 'CSV: ${csvFile.absolute.path}';
    }
  }

  /// Load user data (for backward compatibility with test files)
  static Future<Map<String, String>?> loadUserData() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;
    
    return {
      'user_id': userId,
      'name': 'User', // Placeholder as we only store UUID
      'email': 'user@example.com', // Placeholder
      'phone': '0000000000', // Placeholder
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Save user data to CSV (direct method for backward compatibility)
  static Future<void> saveUserDataToCsv({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    // Use the main saveUserData method which handles CSV saving
    await saveUserData(
      userId: userId,
      name: name,
      email: email,
      phone: phone,
    );
  }

  /// Load user ID from CSV (direct method for backward compatibility)
  static Future<String?> loadUserIdFromCsv() async {
    return await getCurrentUserId();
  }
}