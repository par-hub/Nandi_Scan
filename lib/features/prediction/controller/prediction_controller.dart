import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';

/// Breed prediction state
class BreedPredictionState {
  final bool isLoading;
  final bool isConnected;
  final PredictionResult? lastPrediction;
  final List<PredictionResult> predictionHistory;
  final String? error;

  BreedPredictionState({
    this.isLoading = false,
    this.isConnected = false,
    this.lastPrediction,
    this.predictionHistory = const [],
    this.error,
  });

  BreedPredictionState copyWith({
    bool? isLoading,
    bool? isConnected,
    PredictionResult? lastPrediction,
    List<PredictionResult>? predictionHistory,
    String? error,
  }) {
    return BreedPredictionState(
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      lastPrediction: lastPrediction ?? this.lastPrediction,
      predictionHistory: predictionHistory ?? this.predictionHistory,
      error: error,
    );
  }
}

/// Breed prediction controller using modern Riverpod pattern
class BreedPredictionController extends Notifier<BreedPredictionState> {
  final ImagePicker _imagePicker = ImagePicker();
  
  late ApiService _apiService;

  @override
  BreedPredictionState build() {
    _apiService = ref.watch(apiServiceProvider);
    // Check connection when controller is built (delayed to avoid circular dependency)
    Future.microtask(() => _checkConnection());
    return BreedPredictionState();
  }

  /// Check API connection status
  Future<void> _checkConnection() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final isConnected = await _apiService.testConnection();
      
      if (isConnected) {
        final healthCheck = await _apiService.healthCheck();
        state = state.copyWith(
          isLoading: false,
          isConnected: healthCheck.isHealthy,
          error: healthCheck.isHealthy ? null : healthCheck.error,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isConnected: false,
          error: 'Cannot connect to prediction server',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isConnected: false,
        error: 'Connection error: ${e.toString()}',
      );
    }
  }

  /// Retry connection
  Future<void> retryConnection() async {
    await _checkConnection();
  }

  /// Pick image from gallery and predict
  Future<void> pickFromGalleryAndPredict() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Optimize for API upload
      );

      if (image != null) {
        await predictBreed(image);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  /// Pick image from camera and predict
  Future<void> pickFromCameraAndPredict() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimize for API upload
      );

      if (image != null) {
        await predictBreed(image);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to capture image: ${e.toString()}',
      );
    }
  }

  /// Predict breed from file
  Future<void> predictBreed(XFile imageFile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check connection first
      if (!state.isConnected) {
        await _checkConnection();
        if (!state.isConnected) {
          state = state.copyWith(
            isLoading: false,
            error: 'Not connected to prediction server',
          );
          return;
        }
      }

      // Make prediction
      final result = await _apiService.predictBreed(imageFile);

      if (result.isSuccess) {
        // Add to history
        final updatedHistory = [...state.predictionHistory, result];
        
        state = state.copyWith(
          isLoading: false,
          lastPrediction: result,
          predictionHistory: updatedHistory,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Prediction failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Prediction error: ${e.toString()}',
      );
    }
  }

  /// Clear prediction history
  void clearHistory() {
    state = state.copyWith(
      predictionHistory: [],
      lastPrediction: null,
      error: null,
    );
  }

  /// Clear current error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get supported breeds list
  Future<List<String>> getSupportedBreeds() async {
    try {
      return await _apiService.getSupportedBreeds();
    } catch (e) {
      print('Error getting supported breeds: $e');
      return [];
    }
  }

  /// Batch prediction for multiple images
  Future<void> predictBatch(List<XFile> imageFiles) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (imageFiles.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No images selected',
        );
        return;
      }

      if (imageFiles.length > 10) {
        state = state.copyWith(
          isLoading: false,
          error: 'Maximum 10 images allowed',
        );
        return;
      }

      // Check connection
      if (!state.isConnected) {
        await _checkConnection();
        if (!state.isConnected) {
          state = state.copyWith(
            isLoading: false,
            error: 'Not connected to prediction server',
          );
          return;
        }
      }

      // Make batch prediction
      final results = await _apiService.predictBatch(imageFiles);

      // Add all successful results to history
      final successfulResults = results.where((r) => r.isSuccess).toList();
      final updatedHistory = [...state.predictionHistory, ...successfulResults];

      // Set last prediction to the first successful one
      final lastPrediction = successfulResults.isNotEmpty ? successfulResults.first : null;

      // Check for errors
      final failedResults = results.where((r) => !r.isSuccess).toList();
      final errorMessage = failedResults.isNotEmpty 
          ? 'Some predictions failed: ${failedResults.map((r) => r.error).join(', ')}'
          : null;

      state = state.copyWith(
        isLoading: false,
        lastPrediction: lastPrediction,
        predictionHistory: updatedHistory,
        error: errorMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Batch prediction error: ${e.toString()}',
      );
    }
  }
}

/// Provider for breed prediction controller using modern Riverpod
final breedPredictionControllerProvider = NotifierProvider<BreedPredictionController, BreedPredictionState>(() {
  return BreedPredictionController();
});