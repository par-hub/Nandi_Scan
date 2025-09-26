import 'package:cnn/common/app_theme.dart';
import 'package:cnn/features/Auth/controller/auth_controller_updated.dart';
import 'package:cnn/features/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(userProvider);
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      profileState.when(
                        data: (profile) {
                          final name = profile?.name;
                          return name != null && name.isNotEmpty
                              ? name.substring(0, 1).toUpperCase()
                              : user?.email?.substring(0, 1).toUpperCase() ?? 'U';
                        },
                        loading: () => user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                        error: (_, __) => user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      ),
                      style: textTheme.headlineMedium
                          ?.copyWith(color: AppTheme.primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileState.when(
                          data: (profile) {
                            final name = profile?.name;
                            return Text(
                              name != null && name.isNotEmpty ? name : (user?.email?.split('@').first ?? 'Username'),
                              style: textTheme.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                          loading: () => Text(
                            user?.email?.split('@').first ?? 'Loading...',
                            style: textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          error: (_, __) => Text(
                            user?.email?.split('@').first ?? 'Username',
                            style: textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'No email provided',
                          style: textTheme.bodyMedium?.copyWith(
                              color:
                                  AppTheme.textSecondary.withOpacity(0.6)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Account Details ---
            Text('Account Details', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            profileState.when(
              data: (profile) => Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: profile?.name?.isNotEmpty == true ? profile!.name! : 'Not set',
                  ),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: profile?.phone != null ? profile!.phone!.toStringAsFixed(0) : 'Not set',
                  ),
                  _buildInfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email Address',
                    value: user?.email ?? 'N/A',
                  ),
                ],
              ),
              loading: () => Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: 'Loading...',
                  ),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: 'Loading...',
                  ),
                  _buildInfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email Address',
                    value: user?.email ?? 'N/A',
                  ),
                ],
              ),
              error: (error, _) => Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: 'Error loading data',
                  ),
                  _buildInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    value: 'Error loading data',
                  ),
                  _buildInfoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email Address',
                    value: user?.email ?? 'N/A',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Settings ---
            Text('Settings', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSettingsTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to edit profile screen
              },
            ),
            _buildSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                // TODO: Navigate to notification settings
              },
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () {
                // TODO: Navigate to change password screen
              },
            ),
            const SizedBox(height: 32),

            // --- Logout Button ---
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider).signOut();
                // Navigate to login screen or splash screen
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
      {required IconData icon,
      required String label,
      required String value}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
