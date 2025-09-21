import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/features/registration/controller/registration_controller.dart';

class AnimalRegistrationScreen extends ConsumerStatefulWidget {
  const AnimalRegistrationScreen({super.key});

  @override
  ConsumerState<AnimalRegistrationScreen> createState() =>
      _AnimalRegistrationScreenState();
}

class _AnimalRegistrationScreenState extends ConsumerState<AnimalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _selectedBreed;
  String? _selectedGender;
  bool _isLoading = false;
  List<String> _availableBreeds = [];
  List<String> _availableGenders = [];

  @override
  void initState() {
    super.initState();
    print('Initializing registration screen...'); // Debug print
    // Initialize dropdown data
    _initializeDropdowns();
    print('Breeds loaded: ${_availableBreeds.length}'); // Debug print
    print('Genders loaded: ${_availableGenders.length}'); // Debug print
  }

  void _loadGendersForBreed(String breed) {
    // Since genders are always available, just reset the selection
    print('Breed selected: $breed, resetting gender selection'); // Debug print
    setState(() {
      _selectedGender = null; // Reset gender when breed changes
    });
  }

  Future<void> _registerCattle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBreed == null) {
      _showErrorSnackBar('Please select a breed');
      return;
    }

    if (_selectedGender == null) {
      _showErrorSnackBar('Please select a gender');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert gender from UI format to database format
      String genderCode = _selectedGender == 'Male' ? 'm' : 'f';
      
      // Use the registration controller to upload to Supabase
      final controller = ref.read(registrationControllerProvider);
      final error = await controller.registerCattle(
        breed: _selectedBreed!,
        gender: genderCode,
        height: double.parse(_heightController.text),
        color: _colorController.text.trim(),
        weight: double.parse(_weightController.text),
      );

      if (error == null) {
        _showSuccessSnackBar('Cattle registered successfully to database!');
        _clearForm();
      } else {
        _showErrorSnackBar('Database error: $error');
      }
    } catch (e) {
      _showErrorSnackBar('Registration failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _heightController.clear();
    _colorController.clear();
    _weightController.clear();
    setState(() {
      _selectedBreed = null;
      _selectedGender = null;
      // Reset dropdowns to original values to ensure they work for next registration
      _initializeDropdowns();
    });
  }

  void _initializeDropdowns() {
    // Reinitialize both dropdown lists to ensure they're always available
    _availableBreeds = [
      "Toda","NILI RAVI","Surti","Kankrej","Pandharpuri","Gir","Jaffarabadi","Kenkatha","Banni","NAGPURI","Chilika","Khillar","Kalahandi","Hallikar","Parlakhemundi","Kherigarh","Assam Hill","JAFFARABADI","Manipur Hill","Kishan Garh","Tripura Hill","Hariana","Mizoram Hill","Kuntal","Arunachal Hill","GODAVARI","Sikkim Hill","Ladakhi","Jharkhand Hill","Himachali Pahari","Chhota Nagpuri","Lakhimi","Tibetan Yak","murrah","Andaman Hill","Malvi","Nicobari","Kangayam","Lakshadweep","Mewati","Kashmir Hill","TODA","Lahaul-Spiti","Motu","Kumaon Hill","Amritmahal","Garhwal Hill","Mundari","Brahmagiri Hill","SURTI","Western Ghats Hill","Nagori","Eastern Ghats Hill","Bachaur","Satpura Hill","Nimari","Vindhya Hill","PANDHARPURI","Maikal Hill","Ponwar","Nilgiri Hill","Bargur","Palani Hill","Punganur","Shevaroy Hill","BHADAWARI","Anamalai Hill","Rathi","Cardamom Hill","Dangi","Agasthyamalai Hill","Red Kandhari","Pachamalai Hill","Gaolao","Jawadhu Hill","Siri","Kalrayan Hill","Deoni","Sirumalai Hill","Tharparkar","Sankagiri Hill","MEHSANA","Kolli Hill","Umblachery","Pudukkottai Hill","Dhanni","Sivaganga Hill","Vechur","Dindigul Hill","Ghumusari","Theni Hill","Yak","Virudhunagar Hill","Gangatiri","Tenkasi Hill",
    ];
    _availableGenders = ['Male', 'Female'];
  }

  void _showErrorSnackBar(String message) {
    // Print to console for debugging
    print('ERROR MESSAGE: $message');
    
    // Show in dialog for better copy-ability
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            message,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copy to clipboard
              // Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(context);
            },
            child: const Text('Copy & Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    
    // Also show snackbar for quick reference
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.split('\n').first), // Show only first line in snackbar
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () {
            // Show dialog again if dismissed
            _showErrorDialog(message);
          },
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error Details'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              message,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    // Print to console for debugging
    print('SUCCESS MESSAGE: $message');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
    
    // Also show success dialog with details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Drawer(), // side drawer
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Animal Registration",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Curved top with image placeholder
              Container(
                width: double.infinity,
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                20,
                              ), // Rounded corners, adjust as needed
                            ),
                            child: const Center(
                              child: Text(
                                "Add image",
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              child: Icon(
                                Icons.add_circle,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Breed Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: DropdownButtonFormField<String>(
                  value: _selectedBreed,
                  decoration: InputDecoration(
                    hintText: 'Select Breed',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: _availableBreeds.isEmpty 
                    ? null 
                    : _availableBreeds.map((breed) {
                        return DropdownMenuItem<String>(
                          value: breed,
                          child: Text(breed),
                        );
                      }).toList(),
                  onChanged: _availableBreeds.isEmpty 
                    ? null 
                    : (value) {
                        print('Selected breed: $value'); // Debug print
                        setState(() {
                          _selectedBreed = value;
                        });
                        if (value != null) {
                          _loadGendersForBreed(value);
                        }
                      },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a breed';
                    }
                    return null;
                  },
                ),
              ),

              // Debug info
              if (_availableBreeds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Available breeds: ${_availableBreeds.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              // Gender Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    hintText: 'Select Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: _availableGenders.map((gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    print('Selected gender: $value'); // Debug print
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select gender';
                    }
                    return null;
                  },
                ),
              ),

              // Debug info for genders
              if (_availableGenders.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Available genders: ${_availableGenders.length} (${_availableGenders.join(", ")})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              // Height Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    hintText: 'Height (in cm)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter height';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Please enter a valid height';
                    }
                    return null;
                  },
                ),
              ),

              // Color Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextFormField(
                  controller: _colorController,
                  decoration: InputDecoration(
                    hintText: 'Color',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter color';
                    }
                    return null;
                  },
                ),
              ),

              // Weight Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    hintText: 'Weight (in kg)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Test Connection Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  final controller = ref.read(registrationControllerProvider);
                  final result = await controller.testConnection();
                  _showErrorSnackBar('Connection Test: $result');
                },
                child: const Text(
                  "Test Database Connection",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Register Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _registerCattle,
                      child: const Text(
                        "Register Cattle",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              // Debug Panel
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔧 Debug Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText('Selected Breed: ${_selectedBreed ?? "None"}'),
                    SelectableText('Selected Gender: ${_selectedGender ?? "None"}'),
                    SelectableText('Height: ${_heightController.text.isEmpty ? "Empty" : "${_heightController.text} cm"}'),
                    SelectableText('Color: ${_colorController.text.isEmpty ? "Empty" : _colorController.text}'),
                    SelectableText('Weight: ${_weightController.text.isEmpty ? "Empty" : "${_weightController.text} kg"}'),
                    const SizedBox(height: 8),
                    SelectableText('Available breeds: ${_availableBreeds.length}'),
                    SelectableText('Available genders: ${_availableGenders.length}'),
                    const SizedBox(height: 8),
                    const Text(
                      '💡 All error messages are now copy-able via dialogs',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
}
