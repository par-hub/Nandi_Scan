import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/prediction_controller.dart';
import '../../../services/api_service.dart';

class BreedPredictionScreen extends ConsumerStatefulWidget {
  static const String routeName = '/breed-prediction';
  const BreedPredictionScreen({super.key});

  @override
  ConsumerState<BreedPredictionScreen> createState() => _BreedPredictionScreenState();
}

class _BreedPredictionScreenState extends ConsumerState<BreedPredictionScreen> {
  @override
  void initState() {
    super.initState();
    // Check connection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(breedPredictionControllerProvider.notifier).retryConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final predictionState = ref.watch(breedPredictionControllerProvider);
    final controller = ref.read(breedPredictionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐄 Cattle Breed Prediction'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.retryConnection(),
            tooltip: 'Refresh Connection',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showPredictionHistory(context, predictionState.predictionHistory),
            tooltip: 'Prediction History',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.retryConnection();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              _buildConnectionStatusCard(predictionState, controller),
              const SizedBox(height: 16),

              // Image Selection Card
              _buildImageSelectionCard(predictionState, controller),
              const SizedBox(height: 16),

              // Prediction Result Card
              if (predictionState.lastPrediction != null)
                _buildPredictionResultCard(predictionState.lastPrediction!),
              
              // Error Display
              if (predictionState.error != null)
                _buildErrorCard(predictionState.error!, controller),
              
              const SizedBox(height: 24),
            ],
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
                'Make sure your FastAPI server is running on http://127.0.0.1:8000',
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
            if (result.imageInfo.filename.isNotEmpty) ...[
              Text(
                'Image: ${result.imageInfo.filename}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                'Size: ${result.imageInfo.dimensions.width}×${result.imageInfo.dimensions.height}',
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