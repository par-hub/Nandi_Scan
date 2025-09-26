import 'dart:io';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/common/user_drawer.dart';
import 'package:cnn/features/health/controller/health_controller.dart';
import 'package:cnn/features/health/models/health_model.dart';
import 'package:cnn/services/api_service_fixed.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class HealthScreen extends ConsumerStatefulWidget {
  static const routeName = '/health';
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  final _breedController = TextEditingController();
  String? _selectedGender;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPredicting = false;
  bool _isCheckingHealth = false;
  
  // State for health check results
  List<CommonDisease> _diseases = [];
  String? _lastCheckedBreed;
  String? _errorMessage;

  // Hardcoded list for now, can be moved to a repository later
  final List<String> _availableBreeds = [
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
    "red sindhi",
    "Sahiwal",
    "Ongole",
  ];

  @override
  void dispose() {
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
        });
        _predictBreedFromImage(pickedFile);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _predictBreedFromImage(XFile? imageFile) async {
    if (imageFile == null) return;

    setState(() {
      _isPredicting = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.predictBreed(imageFile);

      if (result.status == 'success' && result.prediction.breed.isNotEmpty) {
        final topPrediction = result.prediction;
        _breedController.text = topPrediction.breed;
        _showSnackBar(
            '🤖 AI Prediction: ${topPrediction.breed} (${(topPrediction.confidence).toStringAsFixed(1)}% confidence)');
      } else {
        _showSnackBar('Could not predict breed. Please enter manually.',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('AI prediction failed. Please enter breed manually.',
          isError: true);
    } finally {
      if (mounted) {
      setState(() {
        _isPredicting = false;
      });
      }
    }
  }

  Future<void> _performHealthCheck() async {
    if (_breedController.text.isEmpty) {
      _showSnackBar('Please select a breed.', isError: true);
      return;
    }

    setState(() {
      _isCheckingHealth = true;
      _errorMessage = null;
      _diseases.clear();
    });

    try {
      final diseases = await ref
          .read(healthControllerProvider)
          .getDiseasesForBreed(_breedController.text);
      
      setState(() {
        _diseases = diseases;
        _lastCheckedBreed = _breedController.text;
        _isCheckingHealth = false;
      });

      if (diseases.isNotEmpty) {
        _showSnackBar('✅ Found ${diseases.length} health condition(s) for ${_breedController.text}');
      } else {
        _showSnackBar('ℹ️ No specific health conditions found for ${_breedController.text}');
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check health: $e';
        _isCheckingHealth = false;
      });
      _showSnackBar('Failed to check health: $e', isError: true);
    }
  }

  void _clearForm() {
    _breedController.clear();
    setState(() {
      _selectedGender = null;
      _selectedImage = null;
      _diseases.clear();
      _lastCheckedBreed = null;
      _errorMessage = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Analysis')),
      drawer: const UserDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(_isCheckingHealth, _isPredicting),
            const SizedBox(height: 16),
            // Show results if we have data
            if (_diseases.isNotEmpty)
              _buildHealthResultsCard(),
            if (_errorMessage != null)
              _buildErrorCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(bool isLoading, bool isPredicting) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analyze Animal Health',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildImagePicker(isPredicting),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _availableBreeds.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _breedController.text = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldController,
                  FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                // Sync with our main controller
                fieldController.text = _breedController.text;
                return TextFormField(
                  controller: fieldController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Breed Name',
                    hintText: 'Enter breed or use AI prediction',
                     suffixIcon: isPredicting
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: ['Male', 'Female']
                  .map((gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _performHealthCheck,
                    icon: isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.health_and_safety_outlined),
                    label: isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Analyzing...'),
                            ],
                          )
                        : const Text('Check Health'),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _clearForm,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isPredicting) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImageSourceDialog(),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: kIsWeb
                        ? Image.network(_selectedImage!.path,
                            fit: BoxFit.cover)
                        : Image.file(File(_selectedImage!.path),
                            fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 40, color: AppTheme.textSecondary),
                      SizedBox(height: 8),
                      Text('Tap to upload for AI prediction'),
                    ],
                  ),
          ),
        ),
        if (isPredicting)
          const Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('AI is analyzing...'),
              ],
            ),
          ),
      ],
    );
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Health Analysis for $_lastCheckedBreed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Found ${_diseases.length} health condition(s)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const Divider(height: 24),
            ...(_diseases.map((disease) => _buildDiseaseCard(disease)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(CommonDisease disease) {
    // Split the disease text into sections if it contains multiple diseases/conditions
    final diseaseText = disease.disease.trim();
    final hasMultipleDiseases = diseaseText.contains('\n\n') || 
                               diseaseText.contains('. ') && diseaseText.length > 200;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Health Conditions (ID: ${disease.id})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: hasMultipleDiseases 
                  ? _buildFormattedDiseaseText(diseaseText)
                  : Text(
                      diseaseText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedDiseaseText(String text) {
    // Split text into sections for better readability
    final sections = text.split(RegExp(r'\n\n|\. (?=[A-Z])'));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final cleanSection = section.trim();
        if (cleanSection.isEmpty) return const SizedBox.shrink();
        
        // Check if this looks like a disease name (short and ends with colon)
        final isDiseaseTitle = cleanSection.length < 100 && 
                              (cleanSection.endsWith(':') || 
                               cleanSection.contains('Disease') ||
                               cleanSection.contains('Disorder'));
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            cleanSection,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isDiseaseTitle ? FontWeight.bold : FontWeight.normal,
              color: isDiseaseTitle ? Colors.red.shade700 : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: AppTheme.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
            const SizedBox(height: 16),
            Text(
              'Health Check Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
