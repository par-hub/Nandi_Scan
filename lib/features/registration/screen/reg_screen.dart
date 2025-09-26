import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/common/glassmorphic_components.dart';
import 'package:cnn/features/registration/controller/registration_controller.dart';
import 'package:cnn/services/api_service_fixed.dart';

class AnimalRegistrationScreen extends ConsumerStatefulWidget {
  static const routeName = '/registration';
  const AnimalRegistrationScreen({super.key});

  @override
  ConsumerState<AnimalRegistrationScreen> createState() =>
      _AnimalRegistrationScreenState();
}

class _AnimalRegistrationScreenState
    extends ConsumerState<AnimalRegistrationScreen> {
  final _breedController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  File? _image;
  XFile? _selectedImage; // For AI prediction
  String? _selectedGender;
  String? _selectedBreed;
  bool _isLoading = false;
  bool _isLoadingBreeds = false;
  bool _isPredicting = false; // For AI prediction loading state
  List<String> _availableBreeds = [];
  List<String> _availableGenders = [];

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  @override
  void dispose() {
    _breedController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadBreeds() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBreeds = true;
    });

    try {
      final registrationController = ref.read(registrationControllerProvider);
      final breeds = await registrationController.getUniqueBreeds();
      
      if (!mounted) return;
      setState(() {
        _availableBreeds = breeds;
        _isLoadingBreeds = false;
      });
    } catch (e) {
      print('Error loading breeds: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingBreeds = false;
      });
      _showErrorSnackBar('Failed to load breeds from database');
    }
  }

  Future<void> _onBreedChanged(String? breed) async {
    if (breed == null || !mounted) return;
    
    setState(() {
      _selectedBreed = breed;
      _breedController.text = breed;
      _selectedGender = null; // Reset gender when breed changes
      _availableGenders = [];
    });

    try {
      final registrationController = ref.read(registrationControllerProvider);
      final genders = await registrationController.getGendersForBreed(breed);
      
      if (!mounted) return;
      setState(() {
        _availableGenders = genders.map((g) => g == 'm' ? 'Male' : 'Female').toList();
      });
    } catch (e) {
      print('Error loading genders for breed: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load genders for selected breed');
      }
    }
  }

  void _clearForm() {
    setState(() {
      _image = null;
      _selectedImage = null;
      _selectedGender = null;
      _selectedBreed = null;
      _breedController.clear();
      _heightController.clear();
      _weightController.clear();
      _colorController.clear();
      _availableGenders = [];
      _isPredicting = false;
    });
  }

  Future<void> _pickImage() async {
    // Show image source selection dialog
    _showImageSourceDialog();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        final imageFile = File(image.path);
        
        // Verify the file exists and is readable
        if (await imageFile.exists()) {
          if (!mounted) return;
          setState(() {
            _image = imageFile;
            _selectedImage = image; // Store XFile for AI prediction
          });
          
          // Trigger AI breed prediction
          _predictBreedFromImage(image);
          
          if (mounted) {
            _showSuccessSnackBar('Image uploaded successfully');
          }
        } else {
          if (mounted) {
            _showErrorSnackBar('Selected image file could not be accessed');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to pick image: ${e.toString()}');
      }
    }
  }

  Future<void> _predictBreedFromImage(XFile? imageFile) async {
    if (imageFile == null || !mounted) return;

    setState(() {
      _isPredicting = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.predictBreed(imageFile);

      if (!mounted) return;
      
      if (result.status == 'success' && result.prediction.breed.isNotEmpty) {
        final topPrediction = result.prediction;
        
        // Set the predicted breed and trigger gender loading
        await _onBreedChanged(topPrediction.breed);
        
        if (mounted) {
          _showSuccessSnackBar(
              '🤖 AI Prediction: ${topPrediction.breed} (${(topPrediction.confidence).toStringAsFixed(1)}% confidence)');
        }
      } else {
        if (mounted) {
          _showSuccessSnackBar('Could not predict breed from image. Please select manually.');
        }
      }
    } catch (e) {
      print('AI prediction error: $e');
      if (mounted) {
        _showSuccessSnackBar('AI prediction unavailable. Please select breed manually.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPredicting = false;
        });
      }
    }
  }

  Widget _buildSafeImage() {
    try {
      if (_image != null && _image!.existsSync()) {
        return Image.file(
          _image!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                'Image file not found',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading image',
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _registerAnimal() async {
    // Image is now optional - no longer required for registration
    
    if (_selectedBreed == null || _selectedBreed!.isEmpty) {
      _showErrorSnackBar('Please select a breed');
      return;
    }

    if (_colorController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter animal color');
      return;
    }

    if (_selectedGender == null) {
      _showErrorSnackBar('Please select gender');
      return;
    }

    if (_heightController.text.trim().isEmpty || _weightController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter height and weight');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse numeric values
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());
      
      if (height == null || weight == null) {
        if (mounted) _showErrorSnackBar('Please enter valid numeric values for height and weight');
        return;
      }

      if (weight <= 0 || height <= 0) {
        if (mounted) _showErrorSnackBar('Height and weight must be positive values');
        return;
      }

      // Use the registration controller instead of direct Supabase calls
      final registrationController = ref.read(registrationControllerProvider);
      
      // Convert gender to single letter format for database
      final genderForDb = _selectedGender!.toLowerCase() == 'male' ? 'm' : 'f';
      
      // Register cattle using the controller
      final result = await registrationController.registerCattle(
        breed: _selectedBreed!,
        gender: genderForDb,
        height: height,
        color: _colorController.text.trim(),
        weight: weight,
      );

      if (!mounted) return;

      if (result == null) {
        // Success - result is null when registration succeeds
        _showSuccessSnackBar('Animal registered successfully!');
        
        // Clear form using helper method
        _clearForm();
      } else {
        // Error - result contains error message
        _showErrorSnackBar(result);
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to register animal: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Register Animal',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Centered Title - Demo Style
                Text(
                  'Register New Cattle',
                  style: AppTheme.headingLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Upload Image Area - Demo Style  
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.textSecondary.withOpacity(0.4),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (_image != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildSafeImage(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Change Image'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _image = null;
                                    _selectedImage = null;
                                    _isPredicting = false;
                                  });
                                  _showSuccessSnackBar('Image removed');
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Remove'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade400,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Icon(
                            Icons.upload_file,
                            size: 48,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to upload animal image',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '🤖 AI will automatically detect the breed',
                            style: AppTheme.labelMedium.copyWith(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                        // Show AI prediction status
                        if (_isPredicting) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '🤖 AI is analyzing breed...',
                                  style: AppTheme.labelMedium.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Breed Selection - Dropdown Style
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Breed Name',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: _isLoadingBreeds
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Loading breeds...',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedBreed,
                            hint: Text(
                              _isPredicting 
                                ? '🤖 AI is predicting breed...'
                                : 'Select breed (e.g., MURRAH, GIR)',
                              style: TextStyle(
                                color: _isPredicting 
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary.withOpacity(0.6)
                              ),
                            ),
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              suffixIcon: _isPredicting 
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                      ),
                                    ),
                                  )
                                : null,
                            ),
                            dropdownColor: AppTheme.backgroundDark,
                            items: _availableBreeds.map((breed) {
                              return DropdownMenuItem<String>(
                                value: breed,
                                child: Text(
                                  breed,
                                  style: const TextStyle(color: AppTheme.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: _isPredicting ? null : _onBreedChanged,
                          ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Color Input - Demo Style
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _colorController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g., Black, White, Brown',
                        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Gender Selection - Dynamic based on breed
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Gender',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_availableGenders.isEmpty && _selectedBreed != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Loading available genders...',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    else if (_availableGenders.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Please select a breed first',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: _availableGenders.map((gender) {
                          final index = _availableGenders.indexOf(gender);
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                right: index < _availableGenders.length - 1 ? 16 : 0
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGender = gender;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _selectedGender == gender
                                        ? AppTheme.primaryGreen.withOpacity(0.2)
                                        : AppTheme.textSecondary.withOpacity(0.1),
                                    border: Border.all(
                                      color: _selectedGender == gender
                                          ? AppTheme.primaryGreen
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        gender == 'Male' ? Icons.male : Icons.female,
                                        color: _selectedGender == gender
                                            ? AppTheme.primaryGreen
                                            : gender == 'Male' ? Colors.blue[400] : Colors.pink[400],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        gender,
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: _selectedGender == gender
                                              ? AppTheme.primaryGreen
                                              : AppTheme.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Height and Weight - Demo Style (Side by side)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Height (cm)',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: '210',
                              hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryGreen),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weight (kg)',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: '750',
                              hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryGreen),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Test Connection Button - Debug Style
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final registrationController = ref.read(registrationControllerProvider);
                        final result = await registrationController.testConnection();
                        
                        // Show result in a dialog
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppTheme.backgroundDark,
                              title: const Text(
                                'Connection Test',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                              content: SingleChildScrollView(
                                child: Text(
                                  result,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: AppTheme.primaryGreen),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } catch (e) {
                        _showErrorSnackBar('Test failed: ${e.toString()}');
                      }
                    },
                    icon: const Icon(Icons.wifi_tethering, size: 20),
                    label: const Text('Test Database Connection'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Register Animal Button - Demo Style
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _registerAnimal,
                    icon: _isLoading 
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 24),
                    label: Text(
                      _isLoading ? 'Registering...' : 'Register Animal',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}