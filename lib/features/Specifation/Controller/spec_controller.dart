import '../Repository/specrepo.dart';

class SpecController {
  final SpecRepository _repository;

  SpecController(this._repository);

  // State variables
  bool _isLoading = false;
  Map<String, dynamic>? _breedData;
  String? _error;
  List<String> _availableBreeds = [];

  // Getters for state
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get breedData => _breedData;
  String? get error => _error;
  List<String> get availableBreeds => _availableBreeds;

  // Initialize available breeds
  Future<void> loadAvailableBreeds() async {
    try {
      _isLoading = true;
      _error = null;

      final breeds = await _repository.getAvailableBreeds();

      _isLoading = false;
      _availableBreeds = breeds;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load available breeds: ${e.toString()}';
    }
  }

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

    try {
      _isLoading = true;
      _error = null;

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
    }
  }

  // Clear data
  void clearData() {
    _breedData = null;
    _error = null;
  }

  // Check if breed is available
  Future<bool> isBreedAvailable(String breedName) async {
    try {
      return await _repository.isBreedAvailable(breedName);
    } catch (e) {
      return false;
    }
  }

  // Get breed suggestions based on input
  List<String> getBreedSuggestions(String input) {
    if (input.trim().isEmpty) {
      return _availableBreeds.take(5).toList();
    }

    final filtered = _availableBreeds
        .where(
          (breed) => breed.toLowerCase().contains(input.toLowerCase().trim()),
        )
        .toList();

    return filtered.take(5).toList();
  }
}
