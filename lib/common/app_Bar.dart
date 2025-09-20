import 'package:flutter/material.dart';
import 'package:cnn/features/Auth/color_palet.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6750A4), // Purple for top 20%
            Colors.white, // White for remaining 80%
          ],
          stops: [0.3, 0.2], // 20% purple, 80% white
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: AppBar(
        title: const Text(
          'Farmer App',
          style: TextStyle(
            color: Colors.black87, // Dark text for contrast on white background
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor:
            Colors.transparent, // Make AppBar transparent to show gradient
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87), // Dark icons
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu), // Drawer icon
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open drawer when tapped
            },
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
