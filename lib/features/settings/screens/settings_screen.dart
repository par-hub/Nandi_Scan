import 'package:flutter/material.dart';
import 'package:cnn/common/user_drawer.dart';
import 'package:cnn/common/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const UserDrawer(),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('App Settings', style: AppTheme.headingMedium),
          const SizedBox(height: 12),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Enable notifications'),
          ),
          const Divider(),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Light'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
