import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/features/Auth/controller/auth_controller_updated.dart';
import 'package:cnn/features/Auth/screens/login_page.dart';
import 'package:cnn/features/cattle/screens/cattle_owned_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserDrawer extends ConsumerStatefulWidget {
  const UserDrawer({super.key});

  @override
  ConsumerState<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends ConsumerState<UserDrawer> {
  String _userName = 'Loading...';
  String _userPhone = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authController = ref.read(authControllerProvider);
      final currentUserId = await authController.getCurrentUserId();
      
      if (currentUserId == null) {
        setState(() {
          _userName = 'Guest User';
          _userPhone = 'Not logged in';
        });
        return;
      }

      print('🔍 Loading user data for ID: $currentUserId');
      
      // Fetch user details from Supabase User_details table
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('User_details')
          .select('name, phone')
          .eq('user-id', currentUserId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _userName = response['name']?.toString() ?? 'Unknown User';
          // Convert phone (float8) to string for display
          final phoneNumber = response['phone'];
          _userPhone = phoneNumber?.toString() ?? 'No phone number';
        });
        print('✅ User data loaded: Name=${_userName}, Phone=${_userPhone}');
      } else {
        print('⚠️ No user details found in database for user ID: $currentUserId');
        setState(() {
          _userName = 'User Details Missing';
          _userPhone = 'Please update profile';
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _userName = 'Error Loading';
        _userPhone = 'Please try again';
      });
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      print('🚪 Starting logout process...');
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Use our auth controller to sign out
      final authController = ref.read(authControllerProvider);
      await authController.signOut();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      print('✅ Logout successful, navigating to login...');

      // Navigate to login page and clear navigation stack
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error during logout: $e');
      
      // Close loading dialog if it's still open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
                    _userName, // Dynamic user name from database
                    style: AppTheme.headingMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _userPhone, // Dynamic phone number from database
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
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
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
              onTap: () => _logout(context, ref),
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