import 'package:flutter/material.dart';
import 'package:cnn/common/user_storage.dart';
import 'package:cnn/common/user_data_debug_screen.dart';

void main() {
  runApp(const UserStorageTestApp());
}

class UserStorageTestApp extends StatelessWidget {
  const UserStorageTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Storage Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UserStorageTestScreen(),
    );
  }
}

class UserStorageTestScreen extends StatefulWidget {
  const UserStorageTestScreen({super.key});

  @override
  State<UserStorageTestScreen> createState() => _UserStorageTestScreenState();
}

class _UserStorageTestScreenState extends State<UserStorageTestScreen> {
  String _statusMessage = '';
  Map<String, dynamic>? _currentUserData;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await UserStorage.getCurrentUserId();
      setState(() {
        if (userId != null) {
          _currentUserData = {'user_id': userId};
          _statusMessage = 'Found existing user UUID: $userId';
        } else {
          _currentUserData = null;
          _statusMessage = 'No existing user UUID found';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a random UUID-like string for testing
      final userId = 'test-${DateTime.now().millisecondsSinceEpoch}';
      
      await UserStorage.saveUserData(
        userId: userId,
        name: _nameController.text.trim(), // These are ignored in CSV-only mode
        email: _emailController.text.trim(), // Only UUID is stored
        phone: _phoneController.text.trim(), // But we keep the API consistent
      );

      setState(() {
        _statusMessage = 'User UUID saved successfully to CSV! ID: $userId';
      });

      // Reload data to show it was saved
      await _loadExistingData();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await UserStorage.clearUserData();
      setState(() {
        _statusMessage = 'User UUID cleared successfully from CSV';
        _currentUserData = null;
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing data: $e';
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
        title: const Text('User Storage Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage.isEmpty ? 'Ready' : _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('Error') ? Colors.red : Colors.green,
                      ),
                    ),
                    if (_currentUserData != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Current User UUID:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('UUID: ${_currentUserData!['user_id']}'),
                      const Text('(CSV-only storage: name, email, phone not stored)'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test User Storage:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveUserData,
                    icon: const Icon(Icons.save),
                    label: const Text('Save User Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadExistingData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reload Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _clearUserData,
                          icon: const Icon(Icons.delete),
                          label: const Text('Clear Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserDataDebugScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Open Debug Screen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}