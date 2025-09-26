import 'package:cnn/common/app_theme.dart';
import 'package:cnn/common/user_drawer.dart';
import 'package:cnn/common/glassmorphic_components.dart';
import 'package:cnn/common/bottom_navigation.dart';
import 'package:cnn/features/registration/screen/reg_screen.dart';
import 'package:cnn/features/cattle/screens/cattle_owned_screen.dart';
import 'package:cnn/features/profile/screens/profile_screen.dart';
import 'package:cnn/features/prediction/screens/breed_prediction_screen.dart';
import 'package:cnn/features/activity/controller/activity_controller.dart';
import 'package:cnn/features/activity/screen/activity_screen.dart';
import 'package:cnn/features/Auth/controller/auth_controller_updated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Home extends ConsumerStatefulWidget {
  static const routeName = '/home';
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  int _currentBottomNavIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _currentBottomNavIndex == 2 ? null : AppBar( // Hide app bar for registration page
          title: Text(
            _getPageTitle(_currentBottomNavIndex),
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                // TODO: Implement notifications
              },
            ),
          ],
        ),
        drawer: const UserDrawer(),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentBottomNavIndex = index;
            });
          },
          children: [
            _buildDashboard(),
            const CattleOwnedScreen(),
            const AnimalRegistrationScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationWidget(
          currentIndex: _currentBottomNavIndex,
          onTabSelected: _onBottomNavTapped,
        ),
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Herd';
      case 2:
        return 'Register Animal';
      case 3:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards Row
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  icon: Icons.grid_view_outlined,
                  count: '12',
                  label: 'Total Cattle',
                  iconColor: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  icon: Icons.warning_amber_outlined,
                  count: '3',
                  label: 'Health Alerts',
                  iconColor: Colors.amber,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // AI Analysis Section
          GlassmorphicCard(
            child: Column(
              children: [
                Text(
                  'AI Analysis',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload an image for instant breed detection or health analysis.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to breed prediction screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BreedPredictionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                      foregroundColor: AppTheme.primaryGreen,
                      side: BorderSide(color: AppTheme.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, ActivityScreen.routeName);
                },
                child: Text(
                  'View All',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Activity List
          _buildRecentActivitiesSection(),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String count,
    required String label,
    required Color iconColor,
  }) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 32,
            color: iconColor,
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: AppTheme.headingLarge.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    final user = ref.watch(userProvider);
    
    if (user == null) {
      return Column(
        children: [
          _buildActivityItem(
            icon: Icons.info_outline,
            iconColor: Colors.orange,
            title: 'Please log in to view activities',
            subtitle: 'Login required',
          ),
        ],
      );
    }

    final activitiesAsync = ref.watch(homeRecentActivitiesProvider(user.id));

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Column(
            children: [
              _buildActivityItem(
                icon: Icons.history,
                iconColor: Colors.grey,
                title: 'No recent activities',
                subtitle: 'Start tracking your cattle activities',
              ),
            ],
          );
        }

        return Column(
          children: activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityItem(
                icon: _getActivityIcon(activity.activity),
                iconColor: AppTheme.primaryGreen,
                title: activity.activity ?? 'No activity description',
                subtitle: _formatActivityTime(activity.dateTime),
                status: 'Cow ${activity.cowId}',
              ),
            );
          }).toList(),
        );
      },
      loading: () => Column(
        children: [
          _buildActivityItem(
            icon: Icons.hourglass_empty,
            iconColor: Colors.blue,
            title: 'Loading activities...',
            subtitle: 'Please wait',
          ),
        ],
      ),
      error: (error, stackTrace) => Column(
        children: [
          _buildActivityItem(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'Failed to load activities',
            subtitle: 'Try again later',
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String? activity) {
    if (activity == null) return Icons.pets;
    
    final desc = activity.toLowerCase();
    if (desc.contains('vaccination') || desc.contains('vaccine')) {
      return Icons.vaccines_outlined;
    } else if (desc.contains('feeding') || desc.contains('feed')) {
      return Icons.restaurant_outlined;
    } else if (desc.contains('health') || desc.contains('checkup')) {
      return Icons.health_and_safety_outlined;
    } else if (desc.contains('breeding') || desc.contains('mate')) {
      return Icons.favorite_outline;
    } else if (desc.contains('treatment') || desc.contains('medicine')) {
      return Icons.medical_services_outlined;
    } else {
      return Icons.pets;
    }
  }

  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? status,
    bool hasChevron = false,
  }) {
    return GlassmorphicCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (status != null)
            Text(
              status,
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (hasChevron)
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
        ],
      ),
    );
  }

}