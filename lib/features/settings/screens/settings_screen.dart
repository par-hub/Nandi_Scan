import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/common/user_drawer.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/services/server_settings_service.dart';
import 'package:cnn/services/api_service_fixed.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String? _connectionStatus;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }
  
  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCurrentSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final settingsService = ref.read(serverSettingsServiceProvider);
      final currentIp = await settingsService.getServerIp();
      final currentPort = await settingsService.getServerPort();
      
      _ipController.text = currentIp;
      _portController.text = currentPort.toString();
    } catch (e) {
      _showSnackBar('Failed to load settings: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final settingsService = ref.read(serverSettingsServiceProvider);
      final ip = _ipController.text.trim();
      final port = int.parse(_portController.text.trim());
      
      final ipSaved = await settingsService.saveServerIp(ip);
      final portSaved = await settingsService.saveServerPort(port);
      
      if (ipSaved && portSaved) {
        _showSnackBar('✅ Server settings saved successfully!');
        
        // Clear any cached server URL in API service to force refresh
        final apiService = ref.read(apiServiceProvider);
        apiService.resetCachedUrl();
        
      } else {
        _showSnackBar('Failed to save settings', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error saving settings: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });
    
    try {
      // Temporarily save settings for testing
      final settingsService = ref.read(serverSettingsServiceProvider);
      await settingsService.saveServerIp(_ipController.text.trim());
      await settingsService.saveServerPort(int.parse(_portController.text.trim()));
      
      // Test connection
      final apiService = ref.read(apiServiceProvider);
      apiService.resetCachedUrl(); // Force refresh
      final healthResult = await apiService.healthCheck();
      
      if (healthResult['status'] == 'healthy') {
        setState(() {
          _connectionStatus = '✅ Connection successful!\nModel loaded: ${healthResult['model_loaded']}\nBreeds available: ${healthResult['breeds_count']}';
        });
      } else {
        setState(() {
          _connectionStatus = '❌ Connection failed: ${healthResult['error'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Connection test failed: $e';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }
  
  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset the server settings to default values. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final settingsService = ref.read(serverSettingsServiceProvider);
        await settingsService.resetToDefaults();
        await _loadCurrentSettings();
        _showSnackBar('✅ Settings reset to defaults');
      } catch (e) {
        _showSnackBar('Failed to reset settings: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const UserDrawer(),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Server Configuration Section
                Text('Server Configuration', style: AppTheme.headingMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configure the IP address and port where your Cattle AI Server is running.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ipController,
                            decoration: const InputDecoration(
                              labelText: 'Server IP Address',
                              hintText: 'e.g., 192.168.1.100 or localhost',
                              prefixIcon: Icon(Icons.computer),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an IP address';
                              }
                              if (!ServerSettingsService.isValidIpAddress(value)) {
                                return 'Please enter a valid IP address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Server Port',
                              hintText: 'e.g., 8001',
                              prefixIcon: Icon(Icons.settings_ethernet),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a port number';
                              }
                              final port = int.tryParse(value);
                              if (port == null || !ServerSettingsService.isValidPort(port)) {
                                return 'Please enter a valid port (1-65535)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isTestingConnection ? null : _saveSettings,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Save Settings'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _isTestingConnection ? null : _testConnection,
                                icon: _isTestingConnection
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.wifi_find),
                                label: Text(_isTestingConnection ? 'Testing...' : 'Test'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_connectionStatus != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _connectionStatus!.startsWith('✅')
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _connectionStatus!.startsWith('✅')
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              child: Text(
                                _connectionStatus!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _resetToDefaults,
                            icon: const Icon(Icons.restore),
                            label: const Text('Reset to Defaults'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App Settings Section
                Text('App Settings', style: AppTheme.headingMedium),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  title: const Text('Enable notifications'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Theme'),
                  subtitle: const Text('Light'),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  title: const Text('About'),
                  subtitle: const Text('Version 1.0.0'),
                  onTap: () {},
                ),
              ],
            ),
    );
  }
}
