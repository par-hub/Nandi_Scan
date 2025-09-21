import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/cattle_repo.dart';
import '../models/cattle_model.dart';

class CattleController {
  final CattleRepo _cattleRepo;

  CattleController(this._cattleRepo);

  /// Get all cattle owned by current user
  Future<List<CattleModel>> getUserCattle() async {
    return await _cattleRepo.getUserCattle();
  }

  /// Get cattle count for current user
  Future<int> getUserCattleCount() async {
    return await _cattleRepo.getUserCattleCount();
  }

  /// Delete a cattle entry
  Future<String?> deleteCattle(int specifiedId) async {
    return await _cattleRepo.deleteCattle(specifiedId);
  }

  /// Update cattle information
  Future<String?> updateCattle(
    int specifiedId, {
    required double height,
    required String color,
    required double weight,
    required String gender,
  }) async {
    // Validate inputs
    if (height <= 0) {
      return "Please enter a valid height";
    }
    if (color.isEmpty) {
      return "Please enter color";
    }
    if (weight <= 0) {
      return "Please enter a valid weight";
    }
    if (gender.isEmpty) {
      return "Please select gender";
    }

    return await _cattleRepo.updateCattle(
      specifiedId,
      height: height,
      color: color,
      weight: weight,
      gender: gender,
    );
  }

  /// Test database connection
  Future<String> testConnection() async {
    return await _cattleRepo.testConnection();
  }
}

final cattleControllerProvider = Provider<CattleController>((ref) {
  final repo = ref.watch(cattleRepo);
  return CattleController(repo);
});

/// Provider for cattle list with auto-refresh capability
final userCattleProvider = FutureProvider<List<CattleModel>>((ref) async {
  final controller = ref.watch(cattleControllerProvider);
  return await controller.getUserCattle();
});

/// Provider for cattle count
final userCattleCountProvider = FutureProvider<int>((ref) async {
  final controller = ref.watch(cattleControllerProvider);
  return await controller.getUserCattleCount();
});