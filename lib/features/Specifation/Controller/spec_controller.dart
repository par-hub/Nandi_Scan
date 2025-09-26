import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/features/Specifation/Repository/specrepo.dart';

final specControllerProvider = Provider((ref) {
  return SpecController(ref.watch(specRepositoryProvider));
});

class SpecController {
  final SpecRepository _repository;

  SpecController(this._repository);

  // State variables
  bool _isLoading = false;
  Map<String, dynamic>? _breedData;
  String? _error;
  List<String> _availableBreeds = [];
  List<Map<String, dynamic>> _allFeaturesData = [];

  // Getters for state
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get breedData => _breedData;
  String? get error => _error;
  List<String> get availableBreeds => _availableBreeds;
  List<Map<String, dynamic>> get allFeaturesData => _allFeaturesData;

  // Fetch breed specifications
  Future<void> fetchBreedSpecifications(
    String breedName, {
    String? gender,
  }) async {
    if (breedName.trim().isEmpty) {
      _error = 'Please enter a breed name';
      _breedData = null;
      return;
    }

    _isLoading = true;
    _error = null;

    try {
      // First, test database access to provide better error messages
      print('🧪 Testing database access...');
      final testResult = await _repository.testDatabaseAccess();
      
      if (!testResult['connection']) {
        throw Exception(
          'Database connection failed. Details: ${testResult['error_details'].join(', ')}'
        );
      }

      print('✅ Database connection successful');
      print('📊 Features table accessible: ${testResult['features_table']}');
      print('📊 Cow_buffalo table accessible: ${testResult['cow_buffalo_table']}');

      final data = await _repository.getBreedSpecifications(
        breedName,
        gender: gender,
      );
      _isLoading = false;
      _breedData = data;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      _breedData = null;
      print('❌ Error in fetchBreedSpecifications: $e');
    }
  }

  // Clear data
  void clearData() {
    _breedData = null;
    _error = null;
  }

  // Test database connectivity
  Future<Map<String, dynamic>> testDatabase() async {
    return await _repository.testDatabaseAccess();
  }
}
