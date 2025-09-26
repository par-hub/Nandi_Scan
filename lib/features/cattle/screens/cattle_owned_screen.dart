import 'package:cnn/common/app_theme.dart';
import 'package:cnn/common/glassmorphic_components.dart';
import 'package:cnn/features/registration/screen/reg_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/cattle_controller.dart';
import '../models/cattle_model.dart';

class CattleOwnedScreen extends ConsumerWidget {
  static const routeName = '/cattle-owned';
  const CattleOwnedScreen({super.key});

  Future<void> _refreshCattle(WidgetRef ref) async {
    ref.invalidate(userCattleProvider);
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cattleAsyncValue = ref.watch(userCattleProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RefreshIndicator(
          onRefresh: () => _refreshCattle(ref),
          child: cattleAsyncValue.when(
            data: (cattleList) {
              if (cattleList.isEmpty) {
                return _buildEmptyState(context);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cattleList.length,
                itemBuilder: (context, index) {
                  final cattle = cattleList[index];
                  return _buildCattleCard(context, ref, cattle);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(ref, error),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pushNamed(AnimalRegistrationScreen.routeName);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Cattle'),
        ),
      ),
    );
  }

  Widget _buildCattleCard(BuildContext context, WidgetRef ref,
      CattleModel cattle) {
    return DarkCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Cattle Image Placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets,
              color: AppTheme.textSecondary,
              size: 32,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Cattle Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${cattle.specifiedId} - ${cattle.breedName ?? 'Unknown Breed'}',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cattle.genderDisplay,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, 
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: () {
                        // TODO: Implement camera/image functionality
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatItem('${cattle.heightInFeet} ft', 'Height'),
                    const SizedBox(width: 16),
                    _buildStatItem('${cattle.weightFormatted} kg', 'Weight'),
                    const SizedBox(width: 16),
                    _buildStatItem(cattle.color, 'Color'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.labelLarge.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets_outlined,
                size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'No Cattle Registered',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get started by adding your first cattle to the herd.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.textSecondary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppTheme.error),
            const SizedBox(height: 24),
            const Text(
              'Failed to Load Cattle',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _refreshCattle(ref),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
