import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/registration_repo.dart';
import '../models/cattle_registration_model.dart';

class RegistrationController {
  final RegistrationRepo _registrationRepo;

  RegistrationController(this._registrationRepo);

  /// Test Supabase connection
  Future<String> testConnection() async {
    return await _registrationRepo.testConnection();
  }

  /// Validate breed and get breed information
  Future<BreedInfo?> validateBreed(String breed, String gender) async {
    if (breed.isEmpty || gender.isEmpty) {
      return null;
    }
    return await _registrationRepo.getBreedInfo(breed, gender);
  }

  /// Get all available breeds
  Future<List<BreedInfo>> getAllBreeds() async {
    return await _registrationRepo.getAllBreeds();
  }

  /// Register new cattle
  Future<String?> registerCattle({
    required String breed,
    required String gender,
    required double height,
    required String color,
    required double weight,
  }) async {
    // Validate inputs
    if (breed.isEmpty) {
      return "Please select a breed";
    }
    if (gender.isEmpty) {
      return "Please select gender";
    }
    if (height <= 0) {
      return "Please enter a valid height";
    }
    if (color.isEmpty) {
      return "Please enter color";
    }
    if (weight <= 0) {
      return "Please enter a valid weight";
    }

    // First validate that the breed exists
    final breedInfo = await validateBreed(breed, gender);
    if (breedInfo == null) {
      return "Selected breed and gender combination not available";
    }

    // Create cattle registration model
    final cattle = CattleRegistrationModel(
      breed: breed,
      gender: gender,
      height: height,
      color: color,
      weight: weight,
    );

    return await _registrationRepo.registerCattle(cattle);
  }

  /// Get user's registered cattle
  Future<List<CattleRegistrationModel>> getUserCattle() async {
    return await _registrationRepo.getUserCattle();
  }

  /// Update existing cattle information
  Future<String?> updateCattle({
    required int specifiedId,
    required String breed,
    required String gender,
    required double height,
    required String color,
    required double weight,
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

    final cattle = CattleRegistrationModel(
      breed: breed,
      gender: gender,
      height: height,
      color: color,
      weight: weight,
    );

    return await _registrationRepo.updateCattle(specifiedId, cattle);
  }

  /// Delete cattle registration
  Future<String?> deleteCattle(int specifiedId) async {
    return await _registrationRepo.deleteCattle(specifiedId);
  }

  /// Get unique breed names for dropdown
  Future<List<String>> getUniqueBreeds() async {
    final breeds = await getAllBreeds();
    return breeds.map((breed) => breed.breed).toSet().toList();
  }

  /// Get genders available for a specific breed
  Future<List<String>> getGendersForBreed(String breed) async {
    final breeds = await getAllBreeds();
    return breeds
        .where((b) => b.breed == breed)
        .map((b) => b.gender)
        .toList();
  }
}

final registrationControllerProvider = Provider<RegistrationController>((ref) {
  final repo = ref.watch(registrationRepo);
  return RegistrationController(repo);
});