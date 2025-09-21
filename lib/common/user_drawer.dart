import 'package:flutter/material.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cnn/features/cattle/screens/cattle_owned_screen.dart';
import 'package:cnn/features/Auth/screens/login_page.dart';
import 'package:cnn/home.dart';
import 'package:cnn/features/Specifation/screens/specification_with_controller.dart';
import 'package:cnn/features/registration/screen/reg_screen.dart';
import 'package:cnn/features/health/screen/health.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut();

      // Navigate to login page
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error during logout')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 34,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'John Doe', // Static user name
                    style: AppTheme.headingMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+1234567890', // Static phone number
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Home.routeName);
              },
            ),
            _drawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // Core navigation
            _drawerItem(
              icon: Icons.pets,
              title: 'Breed Specifications',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, SpecificationScreen.routeName);
              },
            ),
            _drawerItem(
              icon: Icons.app_registration,
              title: 'Animal Registration',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AnimalRegistrationScreen.routeName);
              },
            ),
            _drawerItem(
              icon: Icons.health_and_safety,
              title: 'Health',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Health.routeName);
              },
            ),

            // Cattles Owned Section
            InkWell(
              onTap: () {
                Navigator.pop(context); // close drawer first
                Navigator.pushNamed(context, CattleOwnedScreen.routeName);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.pets, color: AppTheme.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cattles Owned', style: AppTheme.labelLarge),
                          const SizedBox(height: 6),
                          Text('5 Cattles', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),

            _drawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.help_outline,
              title: 'Help',
              onTap: () => Navigator.pop(context),
            ),

            const Divider(),

            // Logout
            _drawerItem(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? AppTheme.textSecondary),
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            color: titleColor ?? AppTheme.textPrimary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
