import 'dart:math';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  static const routeName = '/home';
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Random Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RandomListScreen(),
    );
  }
}

class RandomListScreen extends StatelessWidget {
  const RandomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final random = Random();

    return Scaffold(
      appBar: AppBar(title: const Text("Random Cards")),
      body: ListView.builder(
        itemCount: 20, // 20 random cards
        itemBuilder: (context, index) {
          final number = random.nextInt(100); // 0–99
          final color =
              Colors.primaries[random.nextInt(Colors.primaries.length)];
          return Card(
            color: color.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                "Random Number: $number",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.casino),
            ),
          );
        },
      ),
    );
  }
}
