import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/supabase_config.dart';

class SpecRepository {
  final SupabaseClient _supabase;

  SpecRepository()
    : _supabase = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.supabaseAnonKey,
      );

  /// Fetch all specifications of a given breed
  Future<Map<String, dynamic>> getBreedSpecifications(
    String breedName, {
    String? gender,
  }) async {
    try {
      final normalizedBreed = breedName.toLowerCase().trim();

      // Get data from features table (lowercase as per schema)
      List<Map<String, dynamic>> featuresResponse = [];
      
      print('🔍 Searching for breed: $normalizedBreed');
      
      // First, get the cow_buffalo record to find the correct ID
      var breedQuery = _supabase
          .from('cow_buffalo')
          .select('id, breed, gender, count')
          .ilike('breed', normalizedBreed); // Try exact match first

      if (gender != null && gender.isNotEmpty) {
        breedQuery = breedQuery.eq('gender', gender);
      }

      final breedResponse = await breedQuery.limit(1);
      
      Map<String, dynamic> cowData = {};
      int? specificationId;

      if (breedResponse.isNotEmpty) {
        cowData = breedResponse[0];
        specificationId = cowData['id'];
        print('✅ Found breed in cow_buffalo: ${cowData['breed']} (ID: $specificationId, Gender: ${cowData['gender']})');
      } else {
        // Try with broader search if exact match fails
        print('🔍 Trying broader search for breed: $normalizedBreed');
        final broadQuery = _supabase
            .from('cow_buffalo')
            .select('id, breed, gender, count')
            .textSearch('breed', normalizedBreed);
            
        final broadResponse = await broadQuery.limit(1);
        
        if (broadResponse.isNotEmpty) {
          cowData = broadResponse[0];
          specificationId = cowData['id'];
          print('✅ Found breed with broad search: ${cowData['breed']} (ID: $specificationId)');
        } else {
          print('⚠️ Breed "$breedName" not found in cow_buffalo table');
          // Fallback data
          cowData = {
            'breed': breedName,
            'gender': gender ?? 'Unknown',
            'count': 0,
          };
        }
      }

      // Now get features data using the specification_id
      if (specificationId != null) {
        try {
          final featuresData = await _supabase
              .from('Feautures')
              .select('*')
              .eq('specification_id', specificationId)
              .limit(1);
          
          if (featuresData.isNotEmpty) {
            featuresResponse = featuresData;
            print('✅ Found features for specification_id: $specificationId');
          } else {
            print('⚠️ No features found for specification_id: $specificationId');
          }
          
        } catch (e) {
          print('❌ Error accessing Feautures table: $e');
        }
      }

      // If no specific features found, try to get any available features as fallback
      if (featuresResponse.isEmpty) {
        try {
          final allFeatures = await _supabase
              .from('Feautures')
              .select('*')
              .limit(1);
          
          if (allFeatures.isNotEmpty) {
            featuresResponse = allFeatures;
            print('📋 Using fallback features data from specification_id: ${allFeatures[0]['specification_id']}');
          }
        } catch (e) {
          print('❌ Error getting fallback features: $e');
        }
      }

      // Get the features data from the response
      Map<String, dynamic> data = {};
      if (featuresResponse.isNotEmpty) {
        data = featuresResponse[0];
      }

      return {
        'name': cowData['breed'] ?? breedName,
        'type': cowData['gender'] ?? 'Unknown',
        'origin': 'India', // Default origin for cattle breeds

        /// Physical characteristics from Features table
        'characteristics': {
          'height': data['height']?.toString() ?? 'Unknown',
          'weight': data['weight']?.toString() ?? 'Unknown',
          'color': data['color'] ?? 'Unknown',
          'pattern': data['pattern'] ?? 'Unknown',
          'horn_shape': data['horn_shape'] ?? 'Unknown',
          'ear_shape': data['ear_shape'] ?? 'Unknown',
          'forehead_shape': data['forehead_shape'] ?? 'Unknown',
          'muscle_type': data['muscle_type'] ?? 'Unknown',
          'hump': data['hump'] != null ? (data['hump'] ? 'Present' : 'Absent') : 'Unknown',
        },

        /// Production traits from Features table
        'production': {
          'milk_yield': data['milk_yield']?.toString() ?? 'Unknown',
          'udder': data['udder']?.toString() ?? 'Unknown',
          'teat': data['teat']?.toString() ?? 'Unknown',
          'gestation_period': data['gestation_period']?.toString() ?? 'Unknown',
          'fertility_age': data['fertility_age']?.toString() ?? 'Unknown',
          'purpose': data['purpose'] ?? 'Unknown',
        },

        /// Adaptability features
        'adaptability': {
          'climate_tolerance': 'Good', // Default value as not in current schema
          'disease_resistance': 'Moderate', // Default value
          'feed_efficiency': 'Good', // Default value
          'drought_tolerance': 'Moderate', // Default value
        },

        /// Special features based on distinctive_feature column
        'special_features': data['distinctive_feature'] != null && data['distinctive_feature'].toString().isNotEmpty
            ? [data['distinctive_feature'].toString()]
            : ['Hardy breed', 'Good milk producer', 'Adaptable to local conditions'],

        /// Care requirements (default recommendations)
        'care_requirements': [
          'Regular vaccination schedule',
          'Balanced nutrition and clean water',
          'Proper shelter and ventilation',
          'Regular health check-ups',
          'Parasite control program',
          'Breeding management',
        ],

        /// Raw data for debugging
        'raw_features_data': data,
        'raw_breed_data': cowData,
      };
    } catch (e) {
      throw Exception('Failed to fetch breed specifications: $e');
    }
  }

  /// Get list of all available breeds from CowBuffalo table
  Future<List<String>> getAvailableBreeds() async {
    try {
      final response = await _supabase
          .from('cow_buffalo')
          .select('breed')
          .order('breed');

      if (response.isEmpty) {
        return ['Murrah', 'Bhadawari', 'Jaffarabadi', 'Surti'];
      }

      return response.map<String>((row) => row['breed'] as String).toList();
    } catch (e) {
      return ['Murrah', 'Bhadawari', 'Jaffarabadi', 'Surti'];
    }
  }

  /// Check if a breed exists in DB
  Future<bool> isBreedAvailable(String breedName) async {
    try {
      final normalizedBreed = breedName.toLowerCase().trim();
      
      // First try exact match
      final response = await _supabase
          .from('cow_buffalo')
          .select('id')
          .ilike('breed', normalizedBreed)
          .limit(1);

      if (response.isNotEmpty) {
        return true;
      }

      // Try broader search if exact match fails
      final broadResponse = await _supabase
          .from('cow_buffalo')
          .select('id')
          .textSearch('breed', normalizedBreed)
          .limit(1);

      return broadResponse.isNotEmpty;
    } catch (e) {
      print('❌ Error checking breed availability: $e');
      return false;
    }
  }

  /// Get all features data from Features table for comprehensive display
  Future<List<Map<String, dynamic>>> getAllFeaturesData() async {
    try {
      print('🔍 Fetching all features data...');
      
      final response = await _supabase
          .from('Feautures')
          .select('*')
          .order('specification_id');

      print('✅ Retrieved ${response.length} feature records');
      return response.cast<Map<String, dynamic>>();
      
    } catch (e) {
      print('❌ Error fetching Feautures table: $e');
      print('💡 Possible issues:');
      print('   - RLS policies blocking access');
      print('   - Table permissions not set');
      print('   - Network connectivity issue');
      return [];
    }
  }

  /// Get features by specific criteria
  Future<Map<String, dynamic>?> getFeaturesBySpecificationId(int specificationId) async {
    try {
      print('🔍 Fetching features for specification_id: $specificationId');
      
      final response = await _supabase
          .from('Feautures')
          .select('*')
          .eq('specification_id', specificationId)
          .limit(1);

      if (response.isNotEmpty) {
        print('✅ Found features for specification_id: $specificationId');
        return response[0];
      }
      
      print('⚠️ No features found for specification_id: $specificationId');
      return null;
      
    } catch (e) {
      print('❌ Error fetching features by specification ID: $e');
      return null;
    }
  }

  /// Test database connectivity and table access
  Future<Map<String, dynamic>> testDatabaseAccess() async {
    Map<String, dynamic> testResults = {
      'connection': false,
      'features_table': false,
      'cow_buffalo_table': false,
      'error_details': [],
    };

    try {
      // Test basic connection
      print('🔍 Testing Supabase connection...');
      
      // Test features table access
      try {
        final featuresTest = await _supabase
            .from('Feautures')
            .select('specification_id')
            .limit(1);
        
        testResults['features_table'] = true;
        testResults['features_count'] = featuresTest.length;
        print('✅ Feautures table accessible, found ${featuresTest.length} records');
        
      } catch (e) {
        testResults['error_details'].add('Feautures table error: $e');
        print('❌ Feautures table error: $e');
      }

      // Test cow_buffalo table access  
      try {
        final cowTest = await _supabase
            .from('cow_buffalo')
            .select('id')
            .limit(1);
            
        testResults['cow_buffalo_table'] = true;
        testResults['cow_buffalo_count'] = cowTest.length;
        print('✅ Cow_buffalo table accessible, found ${cowTest.length} records');
        
      } catch (e) {
        testResults['error_details'].add('Cow_buffalo table error: $e');
        print('❌ Cow_buffalo table error: $e');
      }

      testResults['connection'] = testResults['features_table'] || testResults['cow_buffalo_table'];
      
    } catch (e) {
      testResults['error_details'].add('General connection error: $e');
      print('❌ General database connection error: $e');
    }

    return testResults;
  }
}

final specRepositoryProvider = Provider((ref) => SpecRepository());
