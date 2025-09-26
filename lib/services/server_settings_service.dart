import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for managing server configuration settings
class ServerSettingsService {
  static const String _serverIpKey = 'server_ip_address';
  static const String _serverPortKey = 'server_port';
  static const String _defaultIp = '10.12.81.152'; // Current default IP
  static const int _defaultPort = 8001;

  /// Get the saved server IP address
  Future<String> getServerIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIp = prefs.getString(_serverIpKey);
      
      if (savedIp != null && savedIp.isNotEmpty) {
        print('📱 Using saved server IP: $savedIp');
        return savedIp;
      }
      
      print('📱 Using default server IP: $_defaultIp');
      return _defaultIp;
    } catch (e) {
      print('❌ Error getting server IP: $e');
      return _defaultIp;
    }
  }

  /// Save server IP address
  Future<bool> saveServerIp(String ipAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_serverIpKey, ipAddress.trim());
      
      if (success) {
        print('✅ Server IP saved: $ipAddress');
      } else {
        print('❌ Failed to save server IP');
      }
      
      return success;
    } catch (e) {
      print('❌ Error saving server IP: $e');
      return false;
    }
  }

  /// Get the saved server port
  Future<int> getServerPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPort = prefs.getInt(_serverPortKey);
      
      if (savedPort != null && savedPort > 0) {
        print('📱 Using saved server port: $savedPort');
        return savedPort;
      }
      
      print('📱 Using default server port: $_defaultPort');
      return _defaultPort;
    } catch (e) {
      print('❌ Error getting server port: $e');
      return _defaultPort;
    }
  }

  /// Save server port
  Future<bool> saveServerPort(int port) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setInt(_serverPortKey, port);
      
      if (success) {
        print('✅ Server port saved: $port');
      } else {
        print('❌ Failed to save server port');
      }
      
      return success;
    } catch (e) {
      print('❌ Error saving server port: $e');
      return false;
    }
  }

  /// Get complete server URL
  Future<String> getServerUrl() async {
    final ip = await getServerIp();
    final port = await getServerPort();
    return 'http://$ip:$port';
  }

  /// Reset to default settings
  Future<bool> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_serverIpKey);
      await prefs.remove(_serverPortKey);
      print('✅ Server settings reset to defaults');
      return true;
    } catch (e) {
      print('❌ Error resetting server settings: $e');
      return false;
    }
  }

  /// Validate IP address format
  static bool isValidIpAddress(String ip) {
    if (ip.isEmpty) return false;
    
    // Allow localhost variations
    if (ip == 'localhost' || ip == '127.0.0.1') return true;
    
    // Check IPv4 format
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (String part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    
    return true;
  }

  /// Validate port number
  static bool isValidPort(int port) {
    return port > 0 && port <= 65535;
  }
}

/// Provider for server settings service
final serverSettingsServiceProvider = Provider((ref) => ServerSettingsService());