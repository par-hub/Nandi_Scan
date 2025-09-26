import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/common/glassmorphic_components.dart';
import '../controller/prediction_controller.dart';
import '../../../services/api_service_fixed.dart';

class BreedPredictionScreen extends ConsumerStatefulWidget {
  static const String routeName = '/breed-prediction';
  const BreedPredictionScreen({super.key});

  @override
  ConsumerState<BreedPredictionScreen> createState() => _BreedPredictionScreenState();
}

class _BreedPredictionScreenState extends ConsumerState<BreedPredictionScreen> {
  final _breedController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String? _selectedGender = 'Any';
  bool _isLoading = false;

  @override
  void dispose() {
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
        // Auto-predict breed when image is selected
        await _predictBreed();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _predictBreed() async {
    if (_image == null && _breedController.text.trim().isEmpty) {
      _showErrorSnackBar('Please upload an image or enter a breed name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(breedPredictionControllerProvider.notifier);

      if (_image != null) {
        // Use image for prediction
        final xFile = XFile(_image!.path);
        await controller.predictBreed(xFile);
        
        final predictionState = ref.read(breedPredictionControllerProvider);
        if (predictionState.lastPrediction != null) {
          _showSuccessSnackBar('Breed predicted: ${predictionState.lastPrediction!.prediction.breed}');
        }
      } else {
        // Manual breed lookup - just show the input for now
        _showSuccessSnackBar('Searching for: ${_breedController.text}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to predict breed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final predictionState = ref.watch(breedPredictionControllerProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Breed Analysis',
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
                  'Breed Specifications',
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
                        if (_image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _image!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        else ...[
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to upload for AI prediction',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_isLoading)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'AI is analyzing image...',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Breed Name Input - Demo Style
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
                    TextFormField(
                      controller: _breedController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g., Gir, Surti',
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
                
                // Gender Selection - Demo Style (Dropdown)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gender (Optional)',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
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
                      dropdownColor: AppTheme.cardBackground,
                      items: ['Any', 'Female', 'Male'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Find Details Button - Demo Style
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _predictBreed,
                    icon: _isLoading 
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search, size: 24),
                    label: Text(
                      _isLoading ? 'Analyzing...' : 'Find Details',
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
                
                const SizedBox(height: 24),
                
                // Prediction Results - Show if available
                if (predictionState.lastPrediction != null)
                  _buildPredictionResultCard(predictionState.lastPrediction!),
                  
                if (predictionState.error != null)
                  _buildErrorCard(predictionState.error!, ref.read(breedPredictionControllerProvider.notifier)),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(BreedPredictionState state, BreedPredictionController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: state.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Prediction Server Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.isConnected ? 'Connected ✅' : 'Disconnected ❌',
              style: TextStyle(
                color: state.isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!state.isConnected) ...[
              const SizedBox(height: 8),
              const Text(
                'Make sure your AI server is running and configured in Settings',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => controller.retryConnection(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionCard(BreedPredictionState state, BreedPredictionController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Cattle Image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (state.isLoading) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Analyzing image...'),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.isConnected 
                          ? () => controller.pickFromCameraAndPredict()
                          : null,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.isConnected 
                          ? () => controller.pickFromGalleryAndPredict()
                          : null,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            const Text(
              'Tip: Take clear photos of cattle for best results',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionResultCard(PredictionResult result) {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pets, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Prediction Result',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Main Prediction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Predicted Breed:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.prediction.breed,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${result.prediction.confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Top Predictions
            if (result.topPredictions.isNotEmpty) ...[
              Text(
                'Top Predictions:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              ...result.topPredictions.take(5).map((prediction) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          prediction.breed,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${prediction.confidence.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
            const SizedBox(height: 16),
            
            // Image Info
            if (result.imageInfo.name.isNotEmpty) ...[
              Text(
                'Image: ${result.imageInfo.name}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Size: ${result.imageInfo.dimensions}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, BreedPredictionController controller) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => controller.clearError(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPredictionHistory(BuildContext context, List<PredictionResult> history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prediction History'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Text('No predictions yet')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final prediction = history[index];
                    return ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text(prediction.prediction.breed),
                      subtitle: Text(
                        '${prediction.prediction.confidence.toStringAsFixed(1)}% confidence',
                      ),
                      trailing: Text(
                        prediction.timestamp.split('T')[0], // Show date
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (history.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(breedPredictionControllerProvider.notifier).clearHistory();
                Navigator.pop(context);
              },
              child: const Text('Clear History'),
            ),
        ],
      ),
    );
  }
}