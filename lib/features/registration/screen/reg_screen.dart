import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cnn/features/registration/controller/registration_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnimalRegistrationScreen extends ConsumerStatefulWidget {
  static const routeName = '/registration';
  const AnimalRegistrationScreen({super.key});

  @override
  ConsumerState<AnimalRegistrationScreen> createState() =>
      _AnimalRegistrationScreenState();
}

class _AnimalRegistrationScreenState
    extends ConsumerState<AnimalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedBreed;
  String? _selectedGender;
  bool _isLoading = false;
  List<String> _availableBreeds = [];
  List<String> _availableGenders = [];
  String? _currentUserEmail;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Initialize dropdown data
    _initializeDropdowns();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email;
        _currentUserId = user.id;
      });
    }
  }

  void _loadGendersForBreed(String breed) {
    // Since genders are always available, just reset the selection
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
      "Toda",
      "NILI RAVI",
      "Surti",
      "Kankrej",
      "Pandharpuri",
      "Gir",
      "Jaffarabadi",
      "Kenkatha",
      "Banni",
      "NAGPURI",
      "Chilika",
      "Khillar",
      "Kalahandi",
      "Hallikar",
      "Parlakhemundi",
      "Kherigarh",
      "Assam Hill",
      "JAFFARABADI",
      "Manipur Hill",
      "Kishan Garh",
      "Tripura Hill",
      "Hariana",
      "Mizoram Hill",
      "Kuntal",
      "Arunachal Hill",
      "GODAVARI",
      "Sikkim Hill",
      "Ladakhi",
      "Jharkhand Hill",
      "Himachali Pahari",
      "Chhota Nagpuri",
      "Lakhimi",
      "Tibetan Yak",
      "murrah",
      "Andaman Hill",
      "Malvi",
      "Nicobari",
      "Kangayam",
      "Lakshadweep",
      "Mewati",
      "Kashmir Hill",
      "TODA",
      "Lahaul-Spiti",
      "Motu",
      "Kumaon Hill",
      "Amritmahal",
      "Garhwal Hill",
      "Mundari",
      "Brahmagiri Hill",
      "SURTI",
      "Western Ghats Hill",
      "Nagori",
      "Eastern Ghats Hill",
      "Bachaur",
      "Satpura Hill",
      "Nimari",
      "Vindhya Hill",
      "PANDHARPURI",
      "Maikal Hill",
      "Ponwar",
      "Nilgiri Hill",
      "Bargur",
      "Palani Hill",
      "Punganur",
      "Shevaroy Hill",
      "BHADAWARI",
      "Anamalai Hill",
      "Rathi",
      "Cardamom Hill",
      "Dangi",
      "Agasthyamalai Hill",
      "Red Kandhari",
      "Pachamalai Hill",
      "Gaolao",
      "Jawadhu Hill",
      "Siri",
      "Kalrayan Hill",
      "Deoni",
      "Sirumalai Hill",
      "Tharparkar",
      "Sankagiri Hill",
      "MEHSANA",
      "Kolli Hill",
      "Umblachery",
      "Pudukkottai Hill",
      "Dhanni",
      "Sivaganga Hill",
      "Vechur",
      "Dindigul Hill",
      "Ghumusari",
      "Theni Hill",
      "Yak",
      "Virudhunagar Hill",
      "Gangatiri",
      "Tenkasi Hill",
    ];
    _availableGenders = ['Male', 'Female'];
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
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

              // Current User Info
              if (_currentUserEmail != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blue.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Registering for:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText('Email: $_currentUserEmail'),
                      SelectableText(
                        'User ID: ${_currentUserId?.substring(0, 8)}...',
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red.shade50,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please sign in to register cattle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Breed Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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

              // Gender Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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

              // Height Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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

              // Register Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentUserEmail != null
                            ? Colors.black
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _currentUserEmail != null
                          ? _registerCattle
                          : null,
                      child: Text(
                        _currentUserEmail != null
                            ? "Register Cattle"
                            : "Sign In Required",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.lightBlue[100],
    );
  }
}
