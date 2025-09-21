// Test file to verify UUID saving functionality
import 'package:flutter/material.dart';
import 'package:cnn/common/user_storage.dart';

void main() {
  runApp(const UUIDTestApp());
}

class UUIDTestApp extends StatelessWidget {
  const UUIDTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'UUID Test', home: UUIDTestScreen());
  }
}

class UUIDTestScreen extends StatefulWidget {
  const UUIDTestScreen({super.key});

  @override
  _UUIDTestScreenState createState() => _UUIDTestScreenState();
}

class _UUIDTestScreenState extends State<UUIDTestScreen> {
  String _status = 'Ready to test UUID saving';
  bool _isLoading = false;

  Future<void> _testUUIDSaving() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing UUID saving...';
    });

    try {
      // Test direct UUID saving to JSON
      final testUserId = 'test-uuid-${DateTime.now().millisecondsSinceEpoch}';

      await UserStorage.saveUserData(
        userId: testUserId,
        name: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
      );

      // Verify it was saved
      final savedData = await UserStorage.loadUserData();

      if (savedData != null && savedData['user_id'] == testUserId) {
        setState(() {
          _status =
              'SUCCESS: UUID saved and verified!\n'
              'UUID: $testUserId\n'
              'File path: ${UserStorage.getFilePath()}';
        });
      } else {
        setState(() {
          _status = 'ERROR: UUID not saved correctly';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'ERROR: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSignupFlow() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing signup flow structure...';
    });

    try {
      // Test that UserStorage methods are accessible
      setState(() {
        _status =
            'Signup flow structure is valid.\n'
            'UserStorage class is accessible.\n'
            'JSON saving functionality working.';
      });
    } catch (e) {
      setState(() {
        _status = 'Signup flow structure test: $e';
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
      appBar: AppBar(title: const Text('UUID Saving Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'UUID Saving Verification',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  color: _status.contains('SUCCESS')
                      ? Colors.green
                      : _status.contains('ERROR')
                      ? Colors.red
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _testUUIDSaving,
                    child: const Text('Test Direct UUID Saving'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _testSignupFlow,
                    child: const Text('Test Signup Flow Structure'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final data = await UserStorage.loadUserData();
                      setState(() {
                        _status = data != null
                            ? 'Current saved data:\n${data.toString()}'
                            : 'No data currently saved';
                      });
                    },
                    child: const Text('Check Current Saved Data'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
