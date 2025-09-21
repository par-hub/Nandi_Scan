import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/features/health/repository/health_repo.dart';
import 'package:cnn/features/health/models/health_model.dart';

final healthRepoProvider = Provider<HealthRepo>((ref) {
  return HealthRepo();
});

final healthControllerProvider = Provider<HealthController>((ref) {
  return HealthController(
    healthRepo: ref.read(healthRepoProvider),
  );
});

class HealthController {
  final HealthRepo _healthRepo;

  HealthController({required HealthRepo healthRepo}) : _healthRepo = healthRepo;

  /// Test database connection
  Future<String> testConnection() async {
    return await _healthRepo.testConnection();
  }

  /// Get unique breeds for dropdown
  Future<List<String>> getUniqueBreeds() async {
    try {
      return await _healthRepo.getUniqueBreeds();
    } catch (e) {
      print('Controller error getting breeds: $e');
      return [];
    }
  }

  /// Get all common diseases
  Future<List<CommonDisease>> getCommonDiseases() async {
    try {
      return await _healthRepo.getCommonDiseases();
    } catch (e) {
      print('Controller error getting diseases: $e');
      return [];
    }
  }

  /// Get health features for a specific breed
  Future<List<HealthFeature>> getBreedFeatures(String breed) async {
    try {
      return await _healthRepo.getBreedFeatures(breed);
    } catch (e) {
      print('Controller error getting breed features: $e');
      return [];
    }
  }

  /// Get diseases for a specific breed
  Future<List<CommonDisease>> getDiseasesForBreed(String breed) async {
    try {
      return await _healthRepo.getDiseasesForBreed(breed);
    } catch (e) {
      print('Controller error getting diseases for breed: $e');
      return [];
    }
  }

  /// Perform health check analysis
  Future<HealthCheckResult?> performHealthCheck({
    required String breed,
    required String gender,
    required List<String> selectedFeatures,
  }) async {
    try {
      final request = HealthCheckRequest(
        breed: breed,
        gender: gender,
        selectedFeatures: selectedFeatures,
      );
      
      return await _healthRepo.performHealthCheck(request);
    } catch (e) {
      print('Controller error performing health check: $e');
      return null;
    }
  }
}