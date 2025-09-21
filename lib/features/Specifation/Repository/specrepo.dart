import 'package:supabase_flutter/supabase_flutter.dart';
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

      /// Join Feautures with CowBuffalo table using foreign key relation
      var query = _supabase
          .from('Feautures')
          .select('*, cow_buffalo!inner(breed, gender, count)')
          .ilike('cow_buffalo.breed', normalizedBreed);

      if (gender != null && gender.isNotEmpty) {
        query = query.eq('cow_buffalo.gender', gender);
      }

      final response = await query.limit(1);

      if (response.isEmpty) {
        // Changed from response == null
        throw Exception(
          'Breed "$breedName" with gender "${gender ?? ''}" not found in database',
        );
      }

      final data = response[0]; // Get the first element from the list
      final cowData = data['cow_buffalo'] ?? {};

      return {
        'name': cowData['breed'] ?? breedName,
        'type': cowData['gender'] ?? 'Unknown',
        'origin': cowData['count'] ?? 'Unknown',

        /// Breed characteristics
        'characteristics': {
          'color': data['color'] ?? 'Unknown', // Changed from response
          'horn_shape':
              data['horn_shape'] ?? 'Unknown', // Changed from response
          'ear_shape': data['ear_shape'] ?? 'Unknown', // Changed from response
          'forehead_shape':
              data['forehead_shape'] ?? 'Unknown', // Changed from response
          'fertility_age':
              data['fertility_age'] ?? 'Unknown', // Changed from response
          'purpose': data['purpose'] ?? 'Unknown', // Changed from response
          'tail_shape':
              data['tail_shape'] ?? 'Unknown', // Changed from response
          'udder': data['udder'] ?? 'Unknown', // Changed from response
        },

        /// Production traits
        'production': {
          'milk_yield':
              data['milk_yield'] ?? 'Unknown', // Changed from response
          'lactation_yield':
              data['lactation_yield'] ?? 'Unknown', // Changed from response
          'gestation_period':
              data['gestation_period'] ?? 'Unknown', // Changed from response
          'fat_percentage':
              data['fat_percentage'] ?? 'Unknown', // Changed from response
          'weight': data['weight'] ?? 'Unknown', // Changed from response
        },

        /// Health and disease info
        'health': {
          'mastitis_type':
              data['mastitis_type'] ?? 'Unknown', // Changed from response
          'parasites': data['parasites'] ?? 'Unknown', // Changed from response
          'disease': data['disease'] ?? 'Unknown', // Changed from response
        },
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
      final response = await _supabase
          .from('cow_buffalo')
          .select('id')
          .ilike('breed', breedName.toLowerCase().trim())
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
