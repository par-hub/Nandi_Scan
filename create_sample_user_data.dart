import 'dart:convert';
import 'dart:io';

/// Simple utility to create a sample user data file if none exists
void main() {
  final file = File('user_data.json');
  
  if (file.existsSync()) {
    print('✅ User data file already exists at: ${file.absolute.path}');
    try {
      final content = file.readAsStringSync();
      final data = jsonDecode(content);
      print('📱 Current user ID: ${data['user_id']}');
      print('👤 User name: ${data['name']}');
      print('📧 Email: ${data['email']}');
      print('📞 Phone: ${data['phone']}');
      print('📅 Created: ${data['created_at']}');
    } catch (e) {
      print('⚠️ File exists but has invalid JSON: $e');
    }
  } else {
    print('❌ User data file does not exist. Creating sample file...');
    
    final sampleData = {
      'user_id': 'sample-uuid-${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Sample User',
      'email': 'sample@example.com',
      'phone': '1234567890',
      'created_at': DateTime.now().toIso8601String(),
      'last_login': DateTime.now().toIso8601String(),
    };
    
    try {
      file.writeAsStringSync(jsonEncode(sampleData));
      print('✅ Sample user data file created at: ${file.absolute.path}');
      print('📱 Sample user ID: ${sampleData['user_id']}');
      print('');
      print('🔧 You can now test your signup process which will overwrite this sample data');
      print('📋 Or use the debug screen to inspect and manage the file');
    } catch (e) {
      print('❌ Failed to create sample file: $e');
    }
  }
  
  print('');
  print('📍 File location: ${file.absolute.path}');
  print('📝 This file will persist unless manually deleted or cleared via debug screen');
}