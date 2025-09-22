import 'package:cnn/features/health/controller/health_controller.dart';
import 'package:cnn/features/health/models/health_model.dart';
import 'package:cnn/common/user_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../common/widgets/image_picker_widget.dart';
import '../../../services/api_service.dart';

class Health extends ConsumerStatefulWidget {
  static const routeName = '/health';
  const Health({super.key});

  @override
  ConsumerState<Health> createState() => _HealthState();
}

class _HealthState extends ConsumerState<Health> {
  String? _selectedBreed;
  String? _selectedGender;
  List<String> _availableBreeds = [];
  List<String> _availableGenders = ['Male', 'Female'];
  List<CommonDisease> _diseases = [];
  bool _isLoading = false;
  bool _showResults = false;
  bool _isPredictingBreed = false; // Track AI prediction status

  // Image picker variables
  final GlobalKey<ImagePickerWidgetState> _imagePickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeDropdowns();
    _loadCommonDiseases();
  }

  // Image selection callback
  void _onImageSelected(File? file, XFile? webFile) {
    // Auto-predict breed from the selected image
    XFile? imageFile = webFile ?? (file != null ? XFile(file.path) : null);
    if (imageFile != null) {
      _predictBreedFromImage(imageFile);
    }
  }

  void _initializeDropdowns() {
    // Initialize with hardcoded breeds (cleaned and deduplicated)
    _availableBreeds = [
      // Indian breeds
      "Toda",
      "Nili Ravi",
      "Surti",
      "Kankrej",
      "Pandharpuri",
      "Gir",
      "Jaffarabadi",
      "Kenkatha",
      "Banni",
      "Nagpuri",
      "Chilika",
      "Khillar",
      "Kalahandi",
      "Hallikar",
      "Parlakhemundi",
      "Kherigarh",
      "Murrah",
      "Malvi",
      "Kangayam",
      "Mewati",
      "Hariana",
      "Amritmahal",
      "Mundari",
      "Nagori",
      "Bachaur",
      "Nimari",
      "Ponwar",
      "Bargur",
      "Punganur",
      "Rathi",
      "Dangi",
      "Red Kandhari",
      "Gaolao",
      "Siri",
      "Deoni",
      "Tharparkar",
      "Umblachery",
      "Dhanni",
      "Vechur",
      "Ghumusari",
      "Yak",
      "Gangatiri",
      
      // International breeds that AI can predict
      "Angus",
      "Holstein",
      "Holstein Friesian", 
      "Jersey",
      "Brahman",
      "Charolais",
      "Hereford",
      "Limousin",
      "Simmental",
      "Galloway",
      "Brangus",
      "Red Dane",
      
      // Hill breeds
      "Assam Hill",
      "Manipur Hill",
      "Tripura Hill",
      "Mizoram Hill",
      "Arunachal Hill",
      "Sikkim Hill",
      "Jharkhand Hill",
      "Himachali Pahari",
      "Chhota Nagpuri",
      "Lakhimi",
      "Tibetan Yak",
      "Andaman Hill",
      "Nicobari",
      "Lakshadweep",
      "Kashmir Hill",
      "Lahaul-Spiti",
      "Kumaon Hill",
      "Garhwal Hill",
      "Brahmagiri Hill",
      "Western Ghats Hill",
      "Eastern Ghats Hill",
      "Satpura Hill",
      "Vindhya Hill",
      "Maikal Hill",
      "Nilgiri Hill",
      "Palani Hill",
      "Shevaroy Hill",
      "Anamalai Hill",
      "Cardamom Hill",
      "Agasthyamalai Hill",
      "Pachamalai Hill",
      "Jawadhu Hill",
      "Kalrayan Hill",
      "Sirumalai Hill",
      "Sankagiri Hill",
      "Kolli Hill",
      "Pudukkottai Hill",
      "Sivaganga Hill",
      "Dindigul Hill",
      "Theni Hill",
      "Virudhunagar Hill",
      "Tenkasi Hill",
      
      // Other breeds
      "Kishan Garh",
      "Kuntal",
      "Ladakhi",
      "Motu",
      "red sindhi",
      "Sahiwal",
      "Pulikulam",
      "Alambadi",
      "Ongole",
      "Krishna Valley",
      "Thutho",
      "Chhattisgarhi",
      "Gojri",
      "Luit",
      "Marathawadi",
      "Shweta Kapila",
      "Purnea",
      "Pola Thirupu",
      "Nari",
      "Malnad Gidda",
      "Kosali",
      "Kokan Kapila",
      "Khariar",
      "Badri",
      "Belahi",
      "Binjharpuri",
      "Dagri",
      "Thillari",
      "Taylor",
      "Tarai",
      "sunandini",
      "shahabadi",
      "Sanchori",
      "ramgarhi",
    ];
    _availableGenders = ['Male', 'Female'];
  }

  Future<void> _loadCommonDiseases() async {
    try {
      final controller = ref.read(healthControllerProvider);
      final diseases = await controller.getCommonDiseases();
      setState(() {
        _diseases = diseases;
      });
    } catch (e) {
      print('Error loading diseases: $e');
    }
  }

  // AI Breed Prediction Method
  Future<void> _predictBreedFromImage(XFile? imageFile) async {
    if (!mounted || imageFile == null) {
      print('❌ Health screen: Prediction cancelled - mounted: $mounted, imageFile: $imageFile');
      return;
    }
    
    setState(() {
      _isPredictingBreed = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      print('🚀 Health screen: Starting AI prediction...');
      print('📁 Health screen: Image file name: ${imageFile.name}');
      print('📁 Health screen: Image file size: ${await imageFile.length()} bytes');
      
      // First test the health endpoint
      print('🏥 Health screen: Testing API health...');
      final healthResult = await apiService.healthCheck();
      print('🏥 Health screen: Health check - Status: ${healthResult.status}, Model Loaded: ${healthResult.modelLoaded}');
      
      if (!healthResult.isHealthy) {
        print('❌ Health screen: API not healthy, cannot proceed with prediction');
        _showErrorSnackBar('AI service is not available. Please try again later.');
        return;
      }
      
      // Use the web-compatible method
      print('📡 Health screen: Sending prediction request to API...');
      final result = await apiService.predictBreedFromXFile(imageFile);
      
      print('📊 Health screen: AI Response received:');
      print('📊   Status: ${result.status}');
      print('📊   Success: ${result.isSuccess}');
      print('📊   Breed: "${result.prediction.breed}"');
      print('📊   Confidence: ${result.prediction.confidence}%');
      
      if (result.isSuccess && result.prediction.breed.isNotEmpty) {
        // Get the top prediction
        final topPrediction = result.prediction;
        
        print('✅ Health screen: AI prediction successful: "${topPrediction.breed}" with ${topPrediction.confidence}% confidence');
        
        // Only set the breed if it exists in our available breeds list
        if (_availableBreeds.contains(topPrediction.breed)) {
          setState(() {
            _selectedBreed = topPrediction.breed;
          });
          
          _showSuccessSnackBar(
            '🤖 AI Prediction: ${topPrediction.breed} (${(topPrediction.confidence).toStringAsFixed(1)}% confidence)'
          );
        } else {
          // Breed not in our list, show it as a suggestion
          _showSuccessSnackBar(
            '🤖 AI detected: ${topPrediction.breed} (${(topPrediction.confidence).toStringAsFixed(1)}% confidence)\nNote: This breed is not in the health database. Please select a similar breed from the dropdown.'
          );
        }
      } else {
        print('❌ Health screen: AI prediction failed');
        _showErrorSnackBar('Could not predict breed from image. Please select manually.');
      }
    } catch (e, stackTrace) {
      print('💥 Health screen: Exception in breed prediction: $e');
      print('💥 Health screen: Stack trace: $stackTrace');
      _showErrorSnackBar('AI prediction failed. Please select breed manually.');
    } finally {
      if (mounted) {
        setState(() {
          _isPredictingBreed = false;
        });
      }
    }
  }

  Future<void> _performHealthCheck() async {
    if (_selectedBreed == null || _selectedGender == null) {
      _showErrorSnackBar('Please select both breed and gender');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(healthControllerProvider);

      print(
        '🚀 Performing health check for breed: $_selectedBreed, gender: $_selectedGender',
      );

      // First, fetch diseases specific to this breed
      final breedDiseases = await controller.getDiseasesForBreed(
        _selectedBreed!,
      );
      print(
        '📊 Health screen: Found ${breedDiseases.length} diseases for $_selectedBreed',
      );

      // Log the diseases for debugging
      for (int i = 0; i < breedDiseases.length; i++) {
        print('🔍 Disease $i: ${breedDiseases[i].disease}');
      }

      // Then perform the health check (just for validation, not displaying results)
      final result = await controller.performHealthCheck(
        breed: _selectedBreed!,
        gender: _selectedGender == 'Male' ? 'm' : 'f',
        selectedFeatures: [], // For now, empty features
      );

      setState(() {
        _diseases =
            breedDiseases; // Update diseases to show breed-specific ones
        _showResults = true;
      });

      if (result != null) {
        if (breedDiseases.isNotEmpty) {
          _showSuccessSnackBar(
            'Health check completed! Found ${breedDiseases.length} disease(s) for $_selectedBreed',
          );
        } else {
          _showSuccessSnackBar(
            'Health check completed! No specific diseases found for $_selectedBreed (this might indicate database setup is needed)',
          );
        }
      } else {
        _showErrorSnackBar('Health check failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
      print('❌ Health check error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const UserDrawer(), // unified side drawer
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Health Analysis",
          style: TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Curved top with image placeholder
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(60),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    ImagePickerWidget(
                      key: _imagePickerKey,
                      onImageSelected: _onImageSelected,
                      width: 120,
                      height: 120,
                      isCircular: true,
                      placeholder: "Add image",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Breed Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Breed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: _isPredictingBreed 
                          ? Colors.green[50] 
                          : Colors.grey[50],
                      suffixIcon: _isPredictingBreed 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.pets),
                    ),
                    hint: Text(_isPredictingBreed 
                        ? '🤖 AI is predicting...' 
                        : 'Choose a breed (AI prediction available)'),
                    value: _selectedBreed,
                    items: _availableBreeds.map((breed) {
                      return DropdownMenuItem(value: breed, child: Text(breed));
                    }).toList(),
                    onChanged: _isPredictingBreed ? null : (value) {
                      setState(() {
                        _selectedBreed = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Gender Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Gender',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    hint: const Text('Choose gender'),
                    initialValue: _selectedGender,
                    items: _availableGenders.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF43A047),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _isLoading ? null : _performHealthCheck,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Check Health",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 30),

            // Common Diseases Section
            if (_showResults) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedBreed != null
                                ? 'Disease Analysis for $_selectedBreed'
                                : 'Disease Analysis Results',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Debug Info: Found ${_diseases.length} diseases in _diseases list',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      child: SizedBox(
                        height: 250,
                        child: _diseases.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedBreed != null
                                          ? 'No diseases found for $_selectedBreed\n\nThis could mean:\n• Database not set up yet\n• No diseases in database for this breed\n• Connection issue'
                                          : 'No diseases found',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          final controller = ref.read(
                                            healthControllerProvider,
                                          );
                                          final allDiseases = await controller
                                              .getCommonDiseases();
                                          setState(() {
                                            _diseases = allDiseases;
                                          });
                                          _showSuccessSnackBar(
                                            'Loaded ${allDiseases.length} total diseases from database',
                                          );
                                        } catch (e) {
                                          _showErrorSnackBar(
                                            'Failed to load diseases: $e',
                                          );
                                        }
                                      },
                                      child: const Text('Load All Diseases'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _diseases.length,
                                itemBuilder: (context, index) {
                                  final disease = _diseases[index];
                                  final diseaseName = disease.disease.isEmpty
                                      ? 'Disease data missing'
                                      : disease.disease;

                                  print(
                                    '🔍 UI rendering disease $index: ID=${disease.id}, Name="$diseaseName"',
                                  );

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    color: Colors.red.shade50,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.red[100],
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        diseaseName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Disease ID: ${disease.id} | Length: ${disease.disease.length}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: _selectedBreed != null
                                          ? const Icon(
                                              Icons.verified,
                                              color: Colors.green,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
