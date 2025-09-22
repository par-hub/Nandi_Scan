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
  String? _currentUserEmail;
  String? _currentUserId;
  
  // Image picker variables
  File? _selectedImage;
  XFile? _selectedImageWeb; // For web platform
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
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

  Future<void> _registerAnimal() async {
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
    });
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Animal Registration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const UserDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF43A047),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Register Your Cattle',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload an image for AI breed detection and register your animal',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // User Info Section
                  if (_currentUserEmail != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF43A047),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Registering for',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _currentUserEmail!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.badge, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ID: ${_currentUserId?.substring(0, 8)}...',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Please sign in to register cattle',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 25),

                  // Image Upload Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_camera,
                              color: _isPredictingBreed ? Colors.blue : const Color(0xFF43A047),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isPredictingBreed ? 'AI is analyzing...' : 'Upload Animal Image',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isPredictingBreed ? Colors.blue : Colors.grey[800],
                              ),
                            ),
                            if (_isPredictingBreed) ...[
                              const SizedBox(width: 12),
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: _selectedImage != null || _selectedImageWeb != null
                                    ? Colors.green[300]!
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              color: _selectedImage != null || _selectedImageWeb != null
                                  ? Colors.green[50]
                                  : Colors.grey[50],
                            ),
                            child: _selectedImage != null || _selectedImageWeb != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: kIsWeb && _selectedImageWeb != null
                                        ? FutureBuilder<Uint8List>(
                                            future: _selectedImageWeb!.readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Stack(
                                                  children: [
                                                    Image.memory(
                                                      snapshot.data!,
                                                      width: double.infinity,
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                    ),
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.green,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                          )
                                        : _selectedImage != null
                                            ? Stack(
                                                children: [
                                                  Image.file(
                                                    _selectedImage!,
                                                    width: double.infinity,
                                                    height: 200,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: const BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Container()
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Tap to upload animal image',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'AI will automatically detect the breed',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (_isPredictingBreed)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.smart_toy, color: Colors.blue),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'AI is analyzing your image to detect the breed...',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Breed Input Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pets,
                              color: _breedController.text.isNotEmpty ? Colors.green : const Color(0xFF43A047),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Breed Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const Spacer(),
                            if (_breedController.text.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Entered',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _breedController,
                          enabled: !_isPredictingBreed,
                          decoration: InputDecoration(
                            labelText: 'Breed Name',
                            hintText: _isPredictingBreed 
                                ? '🤖 AI is predicting...' 
                                : 'Enter or let AI predict the breed',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFF43A047), width: 2),
                            ),
                            filled: true,
                            fillColor: _isPredictingBreed 
                                ? Colors.blue[50] 
                                : _breedController.text.isNotEmpty 
                                    ? Colors.green[50] 
                                    : Colors.grey[50],
                            prefixIcon: Icon(
                              Icons.search,
                              color: _isPredictingBreed ? Colors.blue : const Color(0xFF43A047),
                            ),
                            suffixIcon: _isPredictingBreed 
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the breed';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Gender Selection Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wc,
                              color: _selectedGender != null ? Colors.green : const Color(0xFF43A047),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Select Gender',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const Spacer(),
                            if (_selectedGender != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Selected',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: ['Male', 'Female'].map((gender) {
                            final isSelected = _selectedGender == gender;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGender = gender;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    right: gender == 'Male' ? 10 : 0,
                                    left: gender == 'Female' ? 10 : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF43A047) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF43A047) : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        gender == 'Male' ? Icons.male : Icons.female,
                                        color: isSelected ? Colors.white : Colors.grey[600],
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        gender,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Additional Info Fields Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF43A047),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Additional Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Height Field
                        TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                            hintText: 'Enter height in centimeters',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFF43A047), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.height, color: Color(0xFF43A047)),
                          ),
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
                        
                        const SizedBox(height: 20),

                        // Color Field
                        TextFormField(
                          controller: _colorController,
                          decoration: InputDecoration(
                            labelText: 'Color',
                            hintText: 'Enter animal color',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFF43A047), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.palette, color: Color(0xFF43A047)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter color';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),

                        // Weight Field
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'Enter weight in kilograms',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFF43A047), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.monitor_weight, color: Color(0xFF43A047)),
                          ),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: _isLoading
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Registering Animal...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _currentUserEmail != null ? _registerAnimal : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentUserEmail != null
                                    ? const Color(0xFF43A047)
                                    : Colors.grey[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: _currentUserEmail != null ? 8 : 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentUserEmail != null 
                                        ? Icons.app_registration 
                                        : Icons.login,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _currentUserEmail != null
                                        ? 'Register Animal'
                                        : 'Sign In Required',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
