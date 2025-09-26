import 'package:cnn/features/activity/screen/activity_screen.dart';
import 'package:cnn/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/features/Auth/controller/auth_controller_updated.dart';
import 'package:cnn/features/Auth/screens/login_page.dart';
import 'package:cnn/features/cattle/screens/cattle_owned_screen.dart';
import 'package:cnn/home.dart';
import 'package:cnn/features/Specifation/screens/specification_with_controller.dart';
import 'package:cnn/features/registration/screen/reg_screen.dart';
import 'package:cnn/features/health/screen/health.dart';

class UserDrawer extends ConsumerWidget {
  const UserDrawer({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(authControllerProvider).signOut();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context)
            .pushNamedAndRemoveUntil(LoginPage.routeName, (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final String userName = user?.userMetadata?['name'] ?? 'Guest User';
    final String userEmail = user?.email ?? 'Not logged in';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: Column(
          children: [
            // Header Section with Glassmorphic effect
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        fontSize: 20, 
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                    _buildDrawerItem(
                      icon: Icons.home_outlined,
                      title: 'Dashboard',
                      onTap: () => _navigateTo(context, Home.routeName),
                      isActive: _isCurrentRoute(context, Home.routeName),
                    ),
                    _buildDrawerItem(
                      icon: Icons.history,
                      title: 'Recent Activity',
                      onTap: () => _navigateTo(context, ActivityScreen.routeName),
                      isActive: _isCurrentRoute(context, ActivityScreen.routeName),
                    ),
                    _buildDrawerItem(
                      icon: Icons.pets_outlined,
                      title: 'My Herd',
                      onTap: () => _navigateTo(context, CattleOwnedScreen.routeName),
                      isActive: _isCurrentRoute(context, CattleOwnedScreen.routeName),
                    ),
                    
                    // Divider
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    
                    _buildDrawerItem(
                      icon: Icons.app_registration,
                      title: 'Register Animal',
                      onTap: () => _navigateTo(context, AnimalRegistrationScreen.routeName),
                      isActive: _isCurrentRoute(context, AnimalRegistrationScreen.routeName),
                    ),
                    _buildDrawerItem(
                      icon: Icons.rule_folder_outlined,
                      title: 'Breed Specifications',
                      onTap: () => _navigateTo(context, SpecificationScreen.routeName),
                      isActive: _isCurrentRoute(context, SpecificationScreen.routeName),
                    ),
                    _buildDrawerItem(
                      icon: Icons.monitor_heart_outlined,
                      title: 'Health Analysis',
                      onTap: () => _navigateTo(context, HealthScreen.routeName),
                      isActive: _isCurrentRoute(context, HealthScreen.routeName),
                    ),
                    
                    // Divider
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    
                    _buildDrawerItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () => _navigateTo(context, SettingsScreen.routeName),
                      isActive: _isCurrentRoute(context, SettingsScreen.routeName),
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Help & Feedback',
                      onTap: () {
                        // TODO: Implement help screen
                      },
                    ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: _buildDrawerItem(
                icon: Icons.logout,
                title: 'Sign Out',
                onTap: () => _logout(context, ref),
                iconColor: AppTheme.error,
                titleColor: AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _isCurrentRoute(BuildContext context, String routeName) {
    return ModalRoute.of(context)?.settings.name == routeName;
  }

  void _navigateTo(BuildContext context, String routeName) {
    // Close the drawer
    Navigator.of(context).pop();
    // Navigate to the new screen, but only if it's not the current screen
    if (ModalRoute.of(context)?.settings.name != routeName) {
      Navigator.of(context).pushNamed(routeName);
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool isActive = false,
  }) {
    final effectiveIconColor = isActive 
        ? AppTheme.primaryGreen 
        : iconColor ?? AppTheme.textSecondary.withOpacity(0.7);
    final effectiveTitleColor = isActive 
        ? AppTheme.primaryGreen 
        : titleColor ?? AppTheme.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: isActive 
          ? BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 1,
              ),
            ) 
          : null,
      child: ListTile(
        leading: Icon(icon, color: effectiveIconColor),
        title: Text(
          title,
          style: TextStyle(
              color: effectiveTitleColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500),
        ),
        onTap: onTap,
        horizontalTitleGap: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
