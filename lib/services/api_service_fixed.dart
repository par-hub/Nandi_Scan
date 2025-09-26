import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'server_settings_service.dart';

/// Provider for API service
final apiServiceProvider = Provider((ref) => ApiService());

/// Dynamic API configuration that uses saved server settings
class ApiConfig {
  static const Duration requestTimeout = Duration(seconds: 30);
  static final ServerSettingsService _settingsService = ServerSettingsService();
  
  // Get dynamic server host from settings
  static Future<String> getServerHost() async {
    return await _settingsService.getServerIp();
  }
  
  // Get dynamic server port from settings
  static Future<int> getServerPort() async {
    return await _settingsService.getServerPort();
  }
  
  // Get dynamic base URL from settings
  static Future<String> getBaseUrl() async {
    return await _settingsService.getServerUrl();
  }
  
  // Static fallback URLs for when settings fail
  static Future<List<String>> getFallbackUrls() async {
    final currentIp = await getServerHost();
    final currentPort = await getServerPort();
    
    return [
      'http://$currentIp:$currentPort',  // Current settings
      'http://10.12.81.152:8001',       // Original default
      'http://localhost:8001',          // For web testing
      'http://127.0.0.1:8001',          // Local fallback
    ];
  }
  
  // Get dynamic health URL
  static Future<String> getHealthUrl() async {
    final baseUrl = await getBaseUrl();
    return '$baseUrl/health';
  }
  
  // Get dynamic prediction URL
  static Future<String> getPredictUrl() async {
    final baseUrl = await getBaseUrl();
    return '$baseUrl/predict';
  }
  
  // Get dynamic breeds URL
  static Future<String> getBreedsUrl() async {
    final baseUrl = await getBaseUrl();
    return '$baseUrl/breeds';
  }
}

/// Enhanced prediction result model
class PredictionResult {
  final String status;
  final String timestamp;
  final ImageInfo imageInfo;
  final Prediction prediction;
  final List<Prediction> topPredictions;
  final ModelInfo modelInfo;
  final String? error;

  PredictionResult({
    required this.status,
    required this.timestamp,
    required this.imageInfo,
    required this.prediction,
    required this.topPredictions,
    required this.modelInfo,
    this.error,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      status: json['status'] ?? 'error',
      timestamp: json['timestamp'] ?? '',
      imageInfo: ImageInfo.fromJson(json['image_info'] ?? {}),
      prediction: Prediction.fromJson(json['prediction'] ?? {}),
      topPredictions: (json['top_predictions'] as List<dynamic>? ?? [])
          .map((item) => Prediction.fromJson(item))
          .toList(),
      modelInfo: ModelInfo.fromJson(json['model_info'] ?? {}),
      error: json['message'],
    );
  }

  factory PredictionResult.error(String errorMessage) {
    return PredictionResult(
      status: 'error',
      timestamp: DateTime.now().toIso8601String(),
      imageInfo: ImageInfo.empty(),
      prediction: Prediction.empty(),
      topPredictions: [],
      modelInfo: ModelInfo.empty(),
      error: errorMessage,
    );
  }
}

class ImageInfo {
  final String name;
  final int size;
  final String format;
  final String dimensions;

  ImageInfo({
    required this.name,
    required this.size,
    required this.format,
    required this.dimensions,
  });

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      format: json['format'] ?? '',
      dimensions: json['dimensions'] ?? '',
    );
  }

  factory ImageInfo.empty() {
    return ImageInfo(name: '', size: 0, format: '', dimensions: '');
  }
}

class Prediction {
  final String breed;
  final double confidence;

  Prediction({
    required this.breed,
    required this.confidence,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      breed: json['breed'] ?? json['prediction'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  factory Prediction.empty() {
    return Prediction(breed: 'Unknown', confidence: 0.0);
  }
}

class ModelInfo {
  final bool loaded;
  final String version;
  final int breedCount;

  ModelInfo({
    required this.loaded,
    required this.version,
    required this.breedCount,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      loaded: json['model_loaded'] ?? false,
      version: json['version'] ?? '',
      breedCount: json['breeds_count'] ?? 0,
    );
  }

  factory ModelInfo.empty() {
    return ModelInfo(loaded: false, version: '', breedCount: 0);
  }
}

/// Main API service for cattle breed prediction
class ApiService {
  final http.Client _client = http.Client();
  String? _currentServerUrl;

  /// Test server health and connectivity
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      print('🏥 Testing API health at $baseUrl...');
      
      // Try primary server first
      try {
        final healthUrl = await ApiConfig.getHealthUrl();
        final response = await _client
            .get(
              Uri.parse(healthUrl),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(ApiConfig.requestTimeout);

        print('📊 Health response: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _currentServerUrl = baseUrl;
          
          print('✅ Server health check passed');
          print('📈 Status: ${data['status']}');
          print('🤖 Model loaded: ${data['model_loaded']}');
          print('🔢 Breeds available: ${data['breeds_count']}');
          
          return {
            'status': 'healthy',
            'model_loaded': data['model_loaded'] ?? false,
            'server_url': _currentServerUrl,
            'breeds_count': data['breeds_count'] ?? 0,
            'response_data': data,
          };
        }
      } catch (e) {
        print('❌ Primary server failed: $e');
      }

      // Try fallback servers
      print('🔄 Trying fallback servers...');
      final fallbackUrls = await ApiConfig.getFallbackUrls();
      for (String fallbackUrl in fallbackUrls) {
        try {
          print('🧪 Testing fallback: $fallbackUrl');
          final response = await _client
              .get(
                Uri.parse('$fallbackUrl/health'),
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            _currentServerUrl = fallbackUrl;
            
            print('✅ Fallback server working: $fallbackUrl');
            return {
              'status': 'healthy',
              'model_loaded': data['model_loaded'] ?? false,
              'server_url': _currentServerUrl,
              'breeds_count': data['breeds_count'] ?? 0,
              'response_data': data,
            };
          }
        } catch (e) {
          print('❌ Fallback $fallbackUrl failed: $e');
          continue;
        }
      }

      return {
        'status': 'error',
        'model_loaded': false,
        'error': 'No server available. Please start the Cattle AI Server on your computer.',
      };
      
    } catch (e) {
      print('❌ Health check error: $e');
      return {
        'status': 'error',
        'model_loaded': false,
        'error': 'Connection failed: $e',
      };
    }
  }

  /// Get list of available breeds
  Future<List<String>> getBreeds() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final serverUrl = _currentServerUrl ?? baseUrl;
      print('📋 Getting breeds from: $serverUrl');
      
      final response = await _client
          .get(
            Uri.parse('$serverUrl/breeds'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final breeds = List<String>.from(data['breeds'] ?? []);
        print('📋 Retrieved ${breeds.length} breeds');
        return breeds;
      } else {
        print('❌ Failed to get breeds: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting breeds: $e');
      return [];
    }
  }

  /// Predict cattle breed from image
  Future<PredictionResult> predictBreed(XFile imageFile) async {
    try {
      print('🚀 Starting breed prediction...');
      print('📁 Image file: ${imageFile.name}');
      
      // Read image file
      final imageBytes = await imageFile.readAsBytes();
      print('📁 Image size: ${imageBytes.length} bytes');

      // Check server health first
      final healthResult = await healthCheck();
      if (healthResult['status'] != 'healthy') {
        return PredictionResult.error(
          'Server not available: ${healthResult['error'] ?? 'Unknown error'}'
        );
      }

      if (healthResult['model_loaded'] != true) {
        return PredictionResult.error(
          'AI model not loaded on server. Please check server status.'
        );
      }

      final baseUrl = await ApiConfig.getBaseUrl();
      final serverUrl = _currentServerUrl ?? baseUrl;
      print('🔗 Using server: $serverUrl');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$serverUrl/predict'),
      );

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.name,
        ),
      );

      // Add headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      print('📤 Sending prediction request...');
      
      // Send request
      final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Prediction response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Prediction successful');
        print('🐄 Predicted breed: ${data['prediction']}');
        print('📈 Confidence: ${data['confidence']}');

        // Create result object
        return PredictionResult(
          status: 'success',
          timestamp: DateTime.now().toIso8601String(),
          imageInfo: ImageInfo(
            name: imageFile.name,
            size: imageBytes.length,
            format: imageFile.name.split('.').last.toLowerCase(),
            dimensions: 'Unknown',
          ),
          prediction: Prediction.fromJson(data),
          topPredictions: (data['top_predictions'] as List<dynamic>? ?? [])
              .map((item) => Prediction.fromJson(item))
              .toList(),
          modelInfo: ModelInfo(
            loaded: true,
            version: '1.0',
            breedCount: healthResult['breeds_count'] ?? 0,
          ),
        );
      } else {
        print('❌ Prediction failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return PredictionResult.error(
          'Prediction failed: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      print('❌ Prediction error: $e');
      return PredictionResult.error('Prediction failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }

  /// Reset cached server URL (useful when settings change)
  void resetCachedUrl() {
    _currentServerUrl = null;
    print('🔄 API service cache reset - will discover server on next request');
  }
}