import 'package:flutter/material.dart';
import '../services/api_service_enhanced.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({Key? key}) : super(key: key);

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _result = 'Not tested yet';
  bool _isLoading = false;

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing...';
    });

    try {
      final apiService = ApiService();
      
      print('🔍 Starting manual API test...');
      final healthResult = await apiService.healthCheck();
      
      setState(() {
        _result = '''
Health Check Result:
Status: ${healthResult.status}
Model Loaded: ${healthResult.modelLoaded}
Supported Breeds: ${healthResult.supportedBreeds}
Model Type: ${healthResult.modelType}
Error: ${healthResult.error ?? 'None'}
Is Healthy: ${healthResult.isHealthy}
        ''';
      });
    } catch (e) {
      setState(() {
        _result = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testApi,
              child: _isLoading 
                ? const CircularProgressIndicator()
                : const Text('Test API Connection'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}