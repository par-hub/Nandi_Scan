import 'dart:io';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/common/user_drawer.dart';
import 'package:cnn/features/Specifation/Controller/spec_controller.dart';
import 'package:cnn/services/api_service_fixed.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class SpecificationScreen extends ConsumerStatefulWidget {
  static const routeName = '/specification-screen';
  const SpecificationScreen({super.key});

  @override
  ConsumerState<SpecificationScreen> createState() =>
      _SpecificationScreenState();
}

class _SpecificationScreenState extends ConsumerState<SpecificationScreen> {
  final _breedController = TextEditingController();
  String? _selectedGender;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isChecking = false;
  bool _isPredicting = false;

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

  Future<void> _checkBreedSpecifications() async {
    if (_breedController.text.isEmpty) {
      _showSnackBar('Please enter a breed name.', isError: true);
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      String? genderParam;
      if (_selectedGender == 'Male') {
        genderParam = 'm';
      } else if (_selectedGender == 'Female') {
        genderParam = 'f';
      }
      await ref
          .read(specControllerProvider)
          .fetchBreedSpecifications(
            _breedController.text,
            gender: genderParam,
          );
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
      setState(() {
        _isChecking = false;
      });
      }
    }
  }

  void _clearData() {
    ref.read(specControllerProvider).clearData();
    _breedController.clear();
    setState(() {
      _selectedGender = null;
      _selectedImage = null;
    });
  }

  Future<void> _testDatabaseConnection() async {
    _showSnackBar('🧪 Testing database connection...', isError: false);
    
    try {
      final testResult = await ref.read(specControllerProvider).testDatabase();
      
      String message = '🔍 Database Test Results:\n';
      message += '• Connection: ${testResult['connection'] ? '✅' : '❌'}\n';
      message += '• Features table: ${testResult['features_table'] ? '✅' : '❌'}\n';
      message += '• Cow_buffalo table: ${testResult['cow_buffalo_table'] ? '✅' : '❌'}';
      
      if (testResult['error_details'].isNotEmpty) {
        message += '\n• Errors: ${testResult['error_details'].join(', ')}';
      }

      _showDialog('Database Test Results', message);
      
    } catch (e) {
      _showSnackBar('Database test failed: $e', isError: true);
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    final specState = ref.watch(specControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Breed Specifications')),
      drawer: const UserDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchCard(_isChecking, _isPredicting),
            const SizedBox(height: 16),
            if (specState.isLoading && !_isChecking)
              const Center(child: CircularProgressIndicator())
            else if (specState.error != null)
              _buildErrorWidget(specState.error!)
            else if (specState.breedData != null)
              _buildSpecificationsCard(specState.breedData!),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(bool isChecking, bool isPredicting) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find Breed Details',
                style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildImagePicker(isPredicting),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breedController,
              decoration: InputDecoration(
                labelText: 'Breed Name',
                hintText: 'Enter breed or let AI predict',
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
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: 'Gender (Optional)'),
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
                    onPressed: isChecking ? null : _checkBreedSpecifications,
                    icon: isChecking
                        ? const SizedBox.shrink()
                        : const Icon(Icons.search),
                    label: isChecking
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
                              Text('Checking...'),
                            ],
                          )
                        : const Text('Check Specs'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _testDatabaseConnection,
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('Test DB'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearData,
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

  Widget _buildErrorWidget(String error) {
    return Card(
      color: AppTheme.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
            const SizedBox(height: 16),
            Text(
              'An Error Occurred',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.error),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationsCard(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name']?.toString() ?? 'Unknown Breed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(data['type']?.toString() ?? 'N/A'),
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            ),
            const Divider(height: 24),
            _buildSection(
              'Physical Characteristics',
              data['characteristics'],
              Icons.straighten_outlined,
            ),
            _buildSection(
              'Production Details',
              data['production'],
              Icons.trending_up,
            ),
            _buildSection(
              'Adaptability',
              data['adaptability'],
              Icons.thermostat_outlined,
            ),
            _buildListSection(
              'Special Features',
              data['special_features'],
              Icons.star_border,
            ),
            _buildListSection(
              'Care Requirements',
              data['care_requirements'],
              Icons.health_and_safety_outlined,
            ),
            if (data['origin'] != null && data['origin'] != 'Unknown')
              _buildSimpleSection(
                  'Origin', data['origin'], Icons.location_on_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic>? details, IconData icon) {
    if (details == null || details.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          for (var entry in details.entries)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key.replaceAll('_', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Text(
                      entry.value?.toString() ?? 'N/A',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic>? items, IconData icon) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          for (var item in items)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSimpleSection(String title, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
          const Divider(),
        ],
      ),
    );
  }
}
