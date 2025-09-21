import 'package:flutter_test/flutter_test.dart';
import 'package:cnn/common/user_storage.dart';
import 'dart:io';

void main() {
  group('UserStorage Tests', () {
    tearDown(() async {
      // Clean up test files - ONLY if this is a test environment
      // Don't delete the file in production/development
      if (Platform.environment['FLUTTER_TEST'] == 'true') {
        final file = File('user_data.json');
        if (await file.exists()) {
          await file.delete();
        }
      }
    });

    test('should save and load user data successfully', () async {
      // Save data using the correct method signature
      await UserStorage.saveUserData(
        userId: 'test-uuid-123',
        name: 'John Doe',
        email: 'test@example.com',
        phone: '1234567890',
      );

      // Load data
      final loadedData = await UserStorage.loadUserData();
      expect(loadedData, isNotNull);
      expect(loadedData!['user_id'], equals('test-uuid-123'));
      expect(loadedData['email'], equals('test@example.com'));
      expect(loadedData['name'], equals('John Doe'));
      expect(loadedData['phone'], equals('1234567890'));
    });

    test('should return current user ID', () async {
      // Save data with user ID
      await UserStorage.saveUserData(
        userId: 'current-user-456',
        name: 'Current User',
        email: 'current@example.com',
        phone: '0987654321',
      );

      // Get current user ID
      final userId = await UserStorage.getCurrentUserId();
      expect(userId, equals('current-user-456'));
    });

    test('should return null when no user data exists', () async {
      // Try to load data when no file exists
      final loadedData = await UserStorage.loadUserData();
      expect(loadedData, isNull);

      // Try to get user ID when no data exists
      final userId = await UserStorage.getCurrentUserId();
      expect(userId, isNull);
    });

    test('should clear user data successfully', () async {
      // Save some data first
      await UserStorage.saveUserData(
        userId: 'to-be-deleted',
        name: 'Delete User',
        email: 'delete@example.com',
        phone: '5555555555',
      );

      // Verify data exists
      var loadedData = await UserStorage.loadUserData();
      expect(loadedData, isNotNull);

      // Clear data
      await UserStorage.clearUserData();

      // Verify data is cleared
      loadedData = await UserStorage.loadUserData();
      expect(loadedData, isNull);
    });

    test('should handle JSON data structure correctly', () async {
      // Test with all optional parameters
      await UserStorage.saveUserData(
        userId: 'full-data-user',
        name: 'Full Name',
        email: 'full@example.com',
        phone: '9876543210',
      );

      final loadedData = await UserStorage.loadUserData();
      expect(loadedData, isNotNull);
      expect(loadedData!.containsKey('user_id'), true);
      expect(loadedData.containsKey('name'), true);
      expect(loadedData.containsKey('email'), true);
      expect(loadedData.containsKey('phone'), true);
      expect(loadedData.containsKey('created_at'), true);
      
      // Verify the created_at timestamp format
      final createdAt = loadedData['created_at'];
      expect(createdAt, isNotNull);
      expect(DateTime.tryParse(createdAt!), isNotNull);
    });
  });
}