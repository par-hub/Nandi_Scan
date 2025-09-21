import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/features/registration/controller/registration_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cnn/services/api_service.dart';
import 'package:cnn/common/user_drawer.dart';

class AnimalRegistrationScreen extends ConsumerStatefulWidget {
  static const routeName = '/registration';
  const AnimalRegistrationScreen({super.key});

  @override
  ConsumerState<AnimalRegistrationScreen> createState() =>
      _AnimalRegistrationScreenState();
}

class _AnimalRegistrationScreenState
    extends ConsumerState<AnimalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _breedController = TextEditingController(); // Add breed text controller

  String? _selectedGender;
  bool _isLoading = false;
  bool _isPredictingBreed = false; // Track AI prediction status
  List<String> _availableGenders = [];
  String? _currentUserEmail;
  String? _currentUserId;
  
  // Image picker variables
  File? _selectedImage;
  XFile? _selectedImageWeb; // For web platform
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize dropdown data
    _initializeDropdowns();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email;
        _currentUserId = user.id;
      });
    }
  }

  void _loadGendersForBreed(String breed) {
    // Since genders are always available, just reset the selection
    setState(() {
      _selectedGender = null; // Reset gender when breed changes
    });
  }

  Future<void> _registerCattle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_breedController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a breed');
      return;
    }

    if (_selectedGender == null) {
      _showErrorSnackBar('Please select a gender');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert gender from UI format to database format
      String genderCode = _selectedGender == 'Male' ? 'm' : 'f';

      // Use the registration controller to upload to Supabase
      final controller = ref.read(registrationControllerProvider);
      final error = await controller.registerCattle(
        breed: _breedController.text.trim(),
        gender: genderCode,
        height: double.parse(_heightController.text),
        color: _colorController.text.trim(),
        weight: double.parse(_weightController.text),
      );

      if (error == null) {
        _showSuccessSnackBar('Cattle registered successfully to database!');
        _clearForm();
      } else {
        _showErrorSnackBar('Database error: $error');
      }
    } catch (e) {
      _showErrorSnackBar('Registration failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _heightController.clear();
    _colorController.clear();
    _weightController.clear();
    _breedController.clear(); // Clear breed text field
    setState(() {
      _selectedGender = null;
      _selectedImage = null; // Clear the selected image
      _selectedImageWeb = null; // Clear web image
      // Reset dropdowns to original values to ensure they work for next registration
      _initializeDropdowns();
    });
  }

  void _initializeDropdowns() {
    // Initialize gender dropdown only (breed is now a text field)
    _availableGenders = ['Male', 'Female'];
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

  // AI Breed Prediction Method
  Future<void> _predictBreedFromImage(XFile? imageFile) async {
    if (!mounted || imageFile == null) {
      print('❌ Prediction cancelled - mounted: $mounted, imageFile: $imageFile');
      return;
    }
    
    setState(() {
      _isPredictingBreed = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      print('🚀 Starting AI prediction...');
      print('📁 Image file name: ${imageFile.name}');
      print('📁 Image file size: ${await imageFile.length()} bytes');
      
      // First test the health endpoint
      print('🏥 Testing API health...');
      final healthResult = await apiService.healthCheck();
      print('🏥 Health check - Status: ${healthResult.status}, Model Loaded: ${healthResult.modelLoaded}');
      
      if (!healthResult.isHealthy) {
        print('❌ API not healthy, cannot proceed with prediction');
        _showErrorSnackBar('AI service is not available. Please try again later.');
        return;
      }
      
      // Use the new web-compatible method
      print('📡 Sending prediction request to API...');
      final result = await apiService.predictBreedFromXFile(imageFile);
      
      print('📊 AI Response received:');
      print('📊   Status: ${result.status}');
      print('📊   Success: ${result.isSuccess}');
      print('📊   Breed: "${result.prediction.breed}"');
      print('📊   Confidence: ${result.prediction.confidence}%');
      print('📊   Error: ${result.error}');
      print('📊   Image Info: ${result.imageInfo.filename} (${result.imageInfo.sizeBytes} bytes)');
      print('📊   Model: ${result.modelInfo.architecture} (${result.modelInfo.totalBreeds} breeds)');
      
      if (result.isSuccess && result.prediction.breed.isNotEmpty) {
        // Get the top prediction
        final topPrediction = result.prediction;
        
        print('✅ AI prediction successful: "${topPrediction.breed}" with ${topPrediction.confidence}% confidence');
        
        // Directly set the breed text field with AI prediction
        setState(() {
          _breedController.text = topPrediction.breed;
        });
        
        // Load genders for the predicted breed
        _loadGendersForBreed(topPrediction.breed);
        
        _showSuccessSnackBar(
          '🤖 AI Prediction: ${topPrediction.breed} (${(topPrediction.confidence).toStringAsFixed(1)}% confidence)'
        );
      } else {
        print('❌ AI prediction failed:');
        print('   Status: ${result.status}');
        print('   Success check: ${result.isSuccess}');
        print('   Breed empty check: ${result.prediction.breed.isEmpty}');
        print('   Actual breed value: "${result.prediction.breed}"');
        _showErrorSnackBar('Could not predict breed from image. Please enter manually.');
      }
    } catch (e, stackTrace) {
      print('💥 Exception in breed prediction: $e');
      print('💥 Stack trace: $stackTrace');
      _showErrorSnackBar('AI prediction failed. Please select breed manually.');
    } finally {
      if (mounted) {
        setState(() {
          _isPredictingBreed = false;
        });
      }
    }
  }

  // Image picker method
  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 80,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        if (kIsWeb) {
                          _selectedImageWeb = pickedFile;
                          _selectedImage = null;
                        } else {
                          _selectedImage = File(pickedFile.path);
                          _selectedImageWeb = null;
                        }
                      });
                      
                      // Auto-predict breed from the selected image
                      _predictBreedFromImage(pickedFile);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pickedFile = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 80,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        if (kIsWeb) {
                          _selectedImageWeb = pickedFile;
                          _selectedImage = null;
                        } else {
                          _selectedImage = File(pickedFile.path);
                          _selectedImageWeb = null;
                        }
                      });
                      
                      // Auto-predict breed from the selected image
                      _predictBreedFromImage(pickedFile);
                    }
                  },
                ),
                if (_selectedImage != null || _selectedImageWeb != null)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Remove Image'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _selectedImageWeb = null;
                      });
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
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
          "Animal Registration",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Curved top with image placeholder
              Container(
                width: double.infinity,
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: _selectedImage != null || _selectedImageWeb != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: kIsWeb && _selectedImageWeb != null
                                          ? FutureBuilder<Uint8List>(
                                              future: _selectedImageWeb!.readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    width: 136,
                                                    height: 136,
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                                return const Center(child: CircularProgressIndicator());
                                              },
                                            )
                                          : _selectedImage != null
                                              ? Image.file(
                                                  _selectedImage!,
                                                  width: 136,
                                                  height: 136,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            color: Colors.teal,
                                            size: 40,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Add image",
                                            style: TextStyle(
                                              color: Colors.teal,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                backgroundColor: Colors.blue,
                                radius: 18,
                                child: Icon(
                                  _selectedImage != null || _selectedImageWeb != null
                                      ? Icons.edit
                                      : Icons.add_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Current User Info
              if (_currentUserEmail != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blue.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Registering for:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText('Email: $_currentUserEmail'),
                      SelectableText(
                        'User ID: ${_currentUserId?.substring(0, 8)}...',
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red.shade50,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please sign in to register cattle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Breed Text Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: TextFormField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    hintText: _isPredictingBreed 
                        ? '🤖 AI is predicting...' 
                        : 'Enter Breed (AI prediction available)',
                    labelText: 'Breed',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: _isPredictingBreed 
                        ? Colors.blue[50] 
                        : Colors.grey[100],
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
                  enabled: !_isPredictingBreed, // Disable while predicting
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a breed';
                    }
                    return null;
                  },
                ),
              ),

              // Gender Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    hintText: 'Select Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: _availableGenders.map((gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select gender';
                    }
                    return null;
                  },
                ),
              ),

              // Height Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    hintText: 'Height (in cm)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter height';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Please enter a valid height';
                    }
                    return null;
                  },
                ),
              ),

              // Color Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: TextFormField(
                  controller: _colorController,
                  decoration: InputDecoration(
                    hintText: 'Color',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter color';
                    }
                    return null;
                  },
                ),
              ),

              // Weight Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    hintText: 'Weight (in kg)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Register Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentUserEmail != null
                            ? Colors.black
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _currentUserEmail != null
                          ? _registerCattle
                          : null,
                      child: Text(
                        _currentUserEmail != null
                            ? "Register Cattle"
                            : "Sign In Required",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
}
