import 'package:cnn/common/app_Bar.dart';
import 'package:cnn/common/app_theme.dart';
import 'package:cnn/features/Auth/widgets/user_drawer.dart';
import 'package:cnn/features/Specifation/screens/specification_with_controller.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  static const routeName = '/home';
  const Home({super.key});
  final List<Map<String, String>> items = const [
    {"title": "Animal Registration", "image": "assets/homereg.jpg"},
    {"title": "Check breed Specifications", "image": "assets/homespec.jpg"},
    {"title": "Health", "image": "assets/Homehealth.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset("assets/homeBackground.jpg", fit: BoxFit.cover),
          ),
          // Gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: AppTheme.cardDecoration,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {
                              final title = item['title'];
                              if (title == 'Check breed Specifications') {
                                Navigator.pushNamed(
                                  context,
                                  SpecificationScreen.routeName,
                                );
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.asset(
                                    item['image']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppTheme.lightGreen.withOpacity(
                                          0.3,
                                        ),
                                        child: const Icon(
                                          Icons.image,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Title
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.agriculture,
                                          color: AppTheme.primaryGreen,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item["title"]!,
                                          style: AppTheme.headingSmall,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const UserDrawer(),
    );
  }
}
