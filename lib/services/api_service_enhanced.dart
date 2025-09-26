import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Provider for API service
final apiServiceProvider = Provider((ref) => ApiService());

/// Dynamic API configuration that works across devices
class ApiConfig {
  // Environment-based configuration
  static const int _defaultPort = 8001;
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Get the base URL dynamically
  static String get baseUrl {
    // Try to get from environment variables first
    final host = Platform.environment['CATTLE_API_HOST'] ?? '10.12.81.152';  // Current network IP
    final portStr = Platform.environment['CATTLE_API_PORT'] ?? _defaultPort.toString();
    final port = int.tryParse(portStr) ?? _defaultPort;
    
    return 'http://$host:$port';
  }
  
  // Alternative URLs to try if main one fails
  static List<String> get fallbackUrls => [
    'http://10.12.81.152:8001',  // Current network IP
    'http://localhost:8001',  // Localhost for web apps
    'http://127.0.0.1:8001',  // Local development (main)
    'http://10.133.117.67:8001',  // Previous network IP
    'http://127.0.0.1:8000',  // Local development (simple)
    'http://localhost:8000',  // Localhost alternative
    'http://0.0.0.0:8001',    // Network accessible
  ];
  
  // Production/deployment URLs (can be set via environment)
  static String? get productionUrl => Platform.environment['CATTLE_API_PRODUCTION_URL'];
  
  // Check if we're in debug mode
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}

/// Server discovery service to find available API endpoints
class ServerDiscovery {
  static final http.Client _client = http.Client();
  
  /// Discover available server endpoints
  static Future<String?> discoverServer() async {
    print('🔍 Starting server discovery...');
    
    // First try production URL if available
    if (ApiConfig.productionUrl != null) {
      print('🧪 Trying production URL: ${ApiConfig.productionUrl}');
      if (await _testEndpoint(ApiConfig.productionUrl!)) {
        print('✅ Production URL working');
        return ApiConfig.productionUrl!;
      }
    }
    
    // Then try the configured base URL
    print('🧪 Trying configured URL: ${ApiConfig.baseUrl}');
    if (await _testEndpoint(ApiConfig.baseUrl)) {
      print('✅ Configured URL working: ${ApiConfig.baseUrl}');
      return ApiConfig.baseUrl;
    }
    
    // Finally try fallback URLs
    print('🧪 Trying fallback URLs...');
    for (String url in ApiConfig.fallbackUrls) {
      print('🧪 Testing: $url');
      if (await _testEndpoint(url)) {
        print('✅ Fallback URL working: $url');
        return url;
      }
    }
    
    print('❌ No working server found');
    return null; // No server found
  }
  
  /// Test if an endpoint is available
  static Future<bool> _testEndpoint(String baseUrl) async {
    try {
      print('🔍 Testing endpoint: $baseUrl/health');
      final response = await _client
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3));
      
      print('📊 Test response for $baseUrl: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test failed for $baseUrl: $e');
      return false;
    }
  }
}

/// Enhanced prediction result model (keeping existing structure)
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

  bool get isSuccess => status == 'success';
}

/// Image information model
class ImageInfo {
  final String filename;
  final int sizeBytes;
  final ImageDimensions dimensions;
  final String format;

  ImageInfo({
    required this.filename,
    required this.sizeBytes,
    required this.dimensions,
    required this.format,
  });

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      filename: json['filename'] ?? '',
      sizeBytes: json['size_bytes'] ?? 0,
      dimensions: ImageDimensions.fromJson(json['dimensions'] ?? {}),
      format: json['format'] ?? '',
    );
  }

  factory ImageInfo.empty() {
    return ImageInfo(
      filename: '',
      sizeBytes: 0,
      dimensions: ImageDimensions.empty(),
      format: '',
    );
  }
}

/// Image dimensions model
class ImageDimensions {
  final int width;
  final int height;

  ImageDimensions({required this.width, required this.height});

  factory ImageDimensions.fromJson(Map<String, dynamic> json) {
    return ImageDimensions(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }

  factory ImageDimensions.empty() {
    return ImageDimensions(width: 0, height: 0);
  }
}

/// Prediction model
class Prediction {
  final String breed;
  final double confidence;
  final double confidenceDecimal;

  Prediction({
    required this.breed,
    required this.confidence,
    required this.confidenceDecimal,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      breed: json['breed'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      confidenceDecimal: (json['confidence_decimal'] ?? 0.0).toDouble(),
    );
  }

  factory Prediction.empty() {
    return Prediction(
      breed: '',
      confidence: 0.0,
      confidenceDecimal: 0.0,
    );
  }
}

/// Model information model
class ModelInfo {
  final String architecture;
  final int totalBreeds;

  ModelInfo({
    required this.architecture,
    required this.totalBreeds,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      architecture: json['architecture'] ?? '',
      totalBreeds: json['total_breeds'] ?? 0,
    );
  }

  factory ModelInfo.empty() {
    return ModelInfo(
      architecture: '',
      totalBreeds: 0,
    );
  }
}

/// Health check result model
class HealthCheckResult {
  final String status;
  final bool modelLoaded;
  final int supportedBreeds;
  final String modelType;
  final String? error;

  HealthCheckResult({
    required this.status,
    required this.modelLoaded,
    required this.supportedBreeds,
    required this.modelType,
    this.error,
  });

  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    return HealthCheckResult(
      status: json['status'] ?? 'error',
      modelLoaded: json['model_loaded'] ?? false,
      supportedBreeds: json['supported_breeds'] ?? 0,
      modelType: json['model_type'] ?? '',
      error: json['message'],
    );
  }

  bool get isHealthy => status == 'healthy' && modelLoaded;
}

/// Enhanced API Service for communicating with FastAPI backend
class ApiService {
  final http.Client _client = http.Client();
  String? _activeBaseUrl;
  
  /// Get the active base URL, discovering server if needed
  Future<String?> _getActiveBaseUrl() async {
    if (_activeBaseUrl != null) {
      return _activeBaseUrl;
    }
    
    _activeBaseUrl = await ServerDiscovery.discoverServer();
    return _activeBaseUrl;
  }

  /// Health check endpoint with server discovery
  Future<HealthCheckResult> healthCheck() async {
    try {
      print('🔍 Starting health check...');
      final baseUrl = await _getActiveBaseUrl();
      if (baseUrl == null) {
        print('❌ No server URL found during discovery');
        return HealthCheckResult(
          status: 'error',
          modelLoaded: false,
          supportedBreeds: 0,
          modelType: '',
          error: 'No server available. Make sure the Python API server is running.',
        );
      }

      print('🌐 Using server URL: $baseUrl');
      final healthUrl = '$baseUrl/health';
      print('📡 Making request to: $healthUrl');

      final response = await _client
          .get(
            Uri.parse(healthUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.requestTimeout);

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = HealthCheckResult.fromJson(data);
        print('✅ Health check success: ${result.status}, Model loaded: ${result.modelLoaded}');
        return result;
      } else {
        print('❌ Health check failed with status: ${response.statusCode}');
        return HealthCheckResult(
          status: 'error',
          modelLoaded: false,
          supportedBreeds: 0,
          modelType: '',
          error: data['message'] ?? 'Health check failed',
        );
      }
    } catch (e) {
      print('❌ Health check exception: $e');
      // Reset the active URL so it will retry discovery next time
      _activeBaseUrl = null;
      return HealthCheckResult(
        status: 'error',
        modelLoaded: false,
        supportedBreeds: 0,
        modelType: '',
        error: 'Connection failed: ${e.toString()}',
      );
    }
  }

  /// Get supported breeds list
  Future<List<String>> getSupportedBreeds() async {
    try {
      final baseUrl = await _getActiveBaseUrl();
      if (baseUrl == null) {
        return [];
      }

      final response = await _client
          .get(
            Uri.parse('$baseUrl/breeds'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['breeds'] ?? []);
      } else {
        throw Exception('Failed to fetch breeds');
      }
    } catch (e) {
      print('Error fetching breeds: $e');
      return [];
    }
  }

  /// Predict cattle breed from image file (deprecated - use predictBreedFromXFile)
  Future<PredictionResult> predictBreed(XFile imageFile) async {
    return predictBreedFromXFile(imageFile);
  }

  /// Predict cattle breed from XFile (cross-platform compatible)
  Future<PredictionResult> predictBreedFromXFile(XFile imageFile) async {
    try {
      final baseUrl = await _getActiveBaseUrl();
      if (baseUrl == null) {
        return PredictionResult.error(
          'No server available. Please check if the Python API server is running and accessible.',
        );
      }

      print('🌐 Starting prediction with server: $baseUrl');
      
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      print('📁 Image read: ${imageBytes.length} bytes');
      
      // Create boundary for multipart form data
      final boundary = '----WebKitFormBoundary${DateTime.now().millisecondsSinceEpoch}';
      
      // Determine content type
      String contentType = 'image/jpeg';
      final extension = _getImageExtension(imageFile.name);
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'bmp':
          contentType = 'image/bmp';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
      }
      
      print('📄 Using content type: $contentType');
      
      // Create multipart body manually for cross-platform compatibility
      final filename = imageFile.name.isNotEmpty ? imageFile.name : 'image.$extension';
      final body = <int>[];
      
      // Add form field
      body.addAll(utf8.encode('--$boundary\r\n'));
      body.addAll(utf8.encode('Content-Disposition: form-data; name="file"; filename="$filename"\r\n'));
      body.addAll(utf8.encode('Content-Type: $contentType\r\n\r\n'));
      body.addAll(imageBytes);
      body.addAll(utf8.encode('\r\n--$boundary--\r\n'));
      
      print('📡 Sending request to $baseUrl/predict');
      
      // Send POST request
      final response = await _client.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'multipart/form-data; boundary=$boundary',
        },
        body: body,
      ).timeout(ApiConfig.requestTimeout);

      print('📨 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Prediction successful!');
        return PredictionResult.fromJson(data);
      } else {
        print('❌ Prediction failed with status ${response.statusCode}');
        return PredictionResult.error(
          data['message'] ?? 'Prediction failed',
        );
      }
    } catch (e) {
      print('💥 Error in prediction: $e');
      // Reset active URL to trigger server rediscovery
      _activeBaseUrl = null;
      return PredictionResult.error(
        'Connection failed: ${e.toString()}',
      );
    }
  }

  /// Batch prediction for multiple images
  Future<List<PredictionResult>> predictBatch(List<XFile> imageFiles) async {
    try {
      final baseUrl = await _getActiveBaseUrl();
      if (baseUrl == null) {
        return [PredictionResult.error('No server available')];
      }

      // Limit batch size
      if (imageFiles.length > 10) {
        throw Exception('Maximum 10 images allowed per batch');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict/batch'),
      );

      // Add all image files - cross-platform compatible way
      for (int i = 0; i < imageFiles.length; i++) {
        final imageBytes = await imageFiles[i].readAsBytes();
        final fileName = imageFiles[i].path.split('/').last.split('\\').last;
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            imageBytes,
            filename: fileName,
          ),
        );
      }

      final streamedResponse = await _client
          .send(request)
          .timeout(ApiConfig.requestTimeout);

      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final results = data['results'] as List<dynamic>;
        return results.map((result) {
          if (result['status'] == 'success') {
            return PredictionResult(
              status: 'success',
              timestamp: DateTime.now().toIso8601String(),
              imageInfo: ImageInfo(
                filename: result['filename'] ?? '',
                sizeBytes: 0,
                dimensions: ImageDimensions.empty(),
                format: '',
              ),
              prediction: Prediction.fromJson(result['prediction'] ?? {}),
              topPredictions: [],
              modelInfo: ModelInfo.empty(),
            );
          } else {
            return PredictionResult.error(result['message'] ?? 'Unknown error');
          }
        }).toList();
      } else {
        throw Exception(data['message'] ?? 'Batch prediction failed');
      }
    } catch (e) {
      print('Error in batch prediction: $e');
      return [PredictionResult.error('Batch prediction failed: ${e.toString()}')];
    }
  }

  /// Get model information
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final baseUrl = await _getActiveBaseUrl();
      if (baseUrl == null) {
        return {};
      }

      final response = await _client
          .get(
            Uri.parse('$baseUrl/model/info'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch model info');
      }
    } catch (e) {
      print('Error fetching model info: $e');
      return {};
    }
  }

  /// Test API connection with server discovery
  Future<bool> testConnection() async {
    try {
      final baseUrl = await _getActiveBaseUrl();
      return baseUrl != null;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  /// Get the current active server URL (for debugging)
  String? get activeServerUrl => _activeBaseUrl;
  
  /// Reset server discovery (force rediscovery)
  void resetServerDiscovery() {
    _activeBaseUrl = null;
  }

  /// Helper function to get image file extension for content type
  String _getImageExtension(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'bmp':
        return 'bmp';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg'; // Default to jpeg
    }
  }

  /// Dispose of HTTP client
  void dispose() {
    _client.close();
  }
}