import 'package:cnn/common/user_storage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class UserDataDebugScreen extends StatefulWidget {
  const UserDataDebugScreen({super.key});

  @override
  State<UserDataDebugScreen> createState() => _UserDataDebugScreenState();
}

class _UserDataDebugScreenState extends State<UserDataDebugScreen> {
  Map<String, dynamic>? userData;
  String? filePath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    
    try {
      final data = await UserStorage.loadUserData();
      final path = UserStorage.getFilePath(); // Now synchronous
      
      setState(() {
        userData = data;
        filePath = path;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userData = null;
        filePath = null;
        isLoading = false;
      });
    }
  }

  Future<void> _clearUserData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Delete'),
        content: const Text(
          'Are you sure you want to permanently delete the user data JSON file?\n\n'
          'This will remove:\n'
          '• User ID\n'
          '• Name, email, phone\n'
          '• Login timestamps\n\n'
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await UserStorage.clearUserData();
      _loadUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ User data file permanently deleted!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Data Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: '⚠️ PERMANENTLY DELETE user data file',
            onPressed: _clearUserData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'File Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            filePath ?? 'File path not available',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                userData != null ? Icons.check_circle : Icons.error,
                                color: userData != null ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userData != null ? 'User Data Found' : 'No User Data',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (userData != null) ...[
                            _buildDataRow('User ID', userData!['user_id']?.toString() ?? 'N/A'),
                            _buildDataRow('Name', userData!['name']?.toString() ?? 'N/A'),
                            _buildDataRow('Email', userData!['email']?.toString() ?? 'N/A'),
                            _buildDataRow('Phone', userData!['phone']?.toString() ?? 'N/A'),
                            _buildDataRow('Created At', userData!['created_at']?.toString() ?? 'N/A'),
                            _buildDataRow('Last Login', userData!['last_login']?.toString() ?? 'N/A'),
                            const SizedBox(height: 16),
                            const Text(
                              'Raw JSON:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: SelectableText(
                                const JsonEncoder.withIndent('  ').convert(userData!),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'No user data file found. User needs to sign up to create the file.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}