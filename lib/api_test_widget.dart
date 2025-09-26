import 'package:flutter/material.dart';
import '../services/api_service_enhanced.dart';

class ApiTestWidget extends StatefulWidget {
  const ApiTestWidget({Key? key}) : super(key: key);

  @override
  State<ApiTestWidget> createState() => _ApiTestWidgetState();
}

class _ApiTestWidgetState extends State<ApiTestWidget> {
  String _testResult = 'Click button to test API';
  bool _isTesting = false;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing API connection...';
    });

    // Test multiple URLs manually
    final testUrls = [
      'http://10.12.81.152:8001',  // Your current network IP
      'http://127.0.0.1:8001',     // Localhost
      'http://localhost:8001',     // Localhost alt
    ];

    for (String url in testUrls) {
      try {
        print('🧪 Testing URL: $url');
        
        // Create a simple HTTP client test
        final response = await ApiService().healthCheck();
        
        setState(() {
          _testResult = '''
🧪 API Test Results:
Testing URL: $url
Status: ${response.status}
Model Loaded: ${response.modelLoaded}
Supported Breeds: ${response.supportedBreeds}
Is Healthy: ${response.isHealthy}
Error: ${response.error ?? 'None'}

✅ Connection test complete!
          ''';
        });
        
        if (response.isHealthy) {
          print('✅ SUCCESS: API working with $url');
          break;
        }
      } catch (e) {
        print('❌ FAILED: $url - $e');
        setState(() {
          _testResult = 'Failed to connect to $url: $e';
        });
      }
    }

    setState(() {
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _isTesting ? null : _testConnection,
            child: Text(_isTesting ? 'Testing...' : 'Test API Connection'),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                _testResult,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}