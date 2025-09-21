import 'package:flutter/material.dart';
import 'package:cnn/common/user_drawer.dart';
import 'package:cnn/common/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const UserDrawer(),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Profile', style: AppTheme.headingMedium),
            const SizedBox(height: 8),
            Text(
              'This is a placeholder profile page. Add user details here (name, phone, email, avatar, etc).',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
