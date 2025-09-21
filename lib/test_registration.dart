import 'package:flutter/material.dart';

class TestRegistrationScreen extends StatefulWidget {
  const TestRegistrationScreen({super.key});

  @override
  State<TestRegistrationScreen> createState() => _TestRegistrationScreenState();
}

class _TestRegistrationScreenState extends State<TestRegistrationScreen> {
  String? _selectedBreed;
  String? _selectedGender;
  
  final List<String> _availableBreeds = [
    'murrah', 'NILI RAVI', 'BHADAWARI', 'JAFFARABADI', 'SURTI', 'MEHSANA', 
    'NAGPURI', 'GODAVARI', 'TODA', 'PANDHARPURI', 'Gaolao', 'Ghumusari', 
    'Gir', 'Hallikar', 'Hariana', 'Himachali Pahari', 'Kangayam', 'Amritmahal',
  ];
  
  final List<String> _availableGenders = ['Male', 'Female'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Registration'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Testing Dropdown Functionality',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // Breed Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBreed,
              decoration: const InputDecoration(
                labelText: 'Select Breed',
                border: OutlineInputBorder(),
              ),
              items: _availableBreeds.map((breed) {
                return DropdownMenuItem<String>(
                  value: breed,
                  child: Text(breed),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBreed = value;
                });
                print('Selected breed: $value');
              },
            ),
            
            const SizedBox(height: 20),
            
            // Gender Dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Select Gender',
                border: OutlineInputBorder(),
              ),
              items: _availableGenders.map((gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
                print('Selected gender: $value');
              },
            ),
            
            const SizedBox(height: 30),
            
            // Display selected values
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Breed: ${_selectedBreed ?? "None"}'),
                  const SizedBox(height: 8),
                  Text('Selected Gender: ${_selectedGender ?? "None"}'),
                  const SizedBox(height: 8),
                  Text('Available breeds count: ${_availableBreeds.length}'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Selected Values'),
                    content: Text('Breed: $_selectedBreed\nGender: $_selectedGender'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Selected Values'),
            ),
          ],
        ),
      ),
    );
  }
}