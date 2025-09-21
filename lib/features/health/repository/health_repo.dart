import 'package:cnn/common/supabase_config.dart';
import 'package:cnn/features/health/models/health_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthRepo {
  final supabase = Supabase.instance.client;

  /// Test Supabase connection for health module
  Future<String> testConnection() async {
    try {
      print('=== TESTING HEALTH MODULE SUPABASE CONNECTION ===');
      print('URL: ${SupabaseConfig.supabaseUrl}');
      print('Attempting to connect...');
      
      // Step 1: Test common_diseases table
      print('Step 1: Testing common_diseases table...');
      final diseasesTest = await supabase
          .from('common_diseases')
          .select('id, disease')  // Using 'disease' as column name
          .limit(5);
          
      print('Step 1 successful! Found ${diseasesTest.length} diseases');
      
      // Step 2: Test Features table
      print('Step 2: Testing Features table...');
      final featuresTest = await supabase
          .from('Features')
          .select('specification_id, height, muscle_type')
          .limit(5);
          
      print('Step 2 successful! Found ${featuresTest.length} feature records');
      
      // Step 3: Test cow_buffalo table (for breeds)
      print('Step 3: Testing cow_buffalo table access...');
      final breedsTest = await supabase
          .from('cow_buffalo')
          .select('id, breed, gender')
          .limit(5);
          
      print('Step 3 successful! Found ${breedsTest.length} breed records');
      
      return """
✅ HEALTH MODULE CONNECTION SUCCESS

URL: ${SupabaseConfig.supabaseUrl}

Test Results:
✅ common_diseases table: PASSED (${diseasesTest.length} records found)
✅ Features table: PASSED (${featuresTest.length} records found)
✅ cow_buffalo table: PASSED (${breedsTest.length} records found)

Sample diseases:
${diseasesTest.take(3).map((e) => '- ${e['disease']}').join('\n')}

All systems ready for health checks!
""";
    } catch (e) {
      print('=== HEALTH MODULE CONNECTION ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Full Error: ${e.toString()}');
      
      String errorAnalysis = "";
      String solution = "";
      
      if (e.toString().contains('common_diseases') && e.toString().contains('does not exist')) {
        errorAnalysis = "❌ common_diseases table does not exist";
        solution = "Create the common_diseases table in Supabase";
      } else if (e.toString().contains('Features') && e.toString().contains('does not exist')) {
        errorAnalysis = "❌ Features table does not exist";
        solution = "Create the Features table in Supabase";
      } else if (e.toString().contains('permission') || e.toString().contains('policy')) {
        errorAnalysis = "❌ Permission/Policy error";
        solution = "Check Row Level Security policies in Supabase dashboard";
      } else {
        errorAnalysis = "❌ Unknown error";
        solution = "Check Supabase URL and API key";
      }
      
      return """
❌ HEALTH MODULE CONNECTION FAILED

$errorAnalysis

Error Type: ${e.runtimeType}
Error Message: $e

URL: ${SupabaseConfig.supabaseUrl}

SOLUTION: $solution

Next Steps:
1. $solution
2. Check Supabase dashboard for table existence
3. Verify RLS policies allow read access
4. Check internet connection

Copy this entire message for debugging.
""";
    }
  }

  /// Get all available breeds from cow_buffalo table
  Future<List<String>> getUniqueBreeds() async {
    try {
      final response = await supabase
          .from('cow_buffalo')
          .select('breed')
          .order('breed');
      
      // Extract unique breed names
      final breeds = (response as List)
          .map((item) => item['breed'] as String)
          .toSet()
          .toList();
      
      breeds.sort(); // Sort alphabetically
      return breeds;
    } catch (e) {
      print('Error fetching breeds for health module: $e');
      // Return hardcoded list as fallback
      return [
        "Toda","NILI RAVI","Surti","Kankrej","Pandharpuri","Gir","Jaffarabadi","Kenkatha","Banni","NAGPURI","Chilika","Khillar","Kalahandi","Hallikar","Parlakhemundi","Kherigarh","Assam Hill","JAFFARABADI","Manipur Hill","Kishan Garh","Tripura Hill","Hariana","Mizoram Hill","Kuntal","Arunachal Hill","GODAVARI","Sikkim Hill","Ladakhi","Jharkhand Hill","Himachali Pahari","Chhota Nagpuri","Lakhimi","Tibetan Yak","murrah","Andaman Hill","Malvi","Nicobari","Kangayam","Lakshadweep","Mewati","Kashmir Hill","TODA","Lahaul-Spiti","Motu","Kumaon Hill","Amritmahal","Garhwal Hill","Mundari","Brahmagiri Hill","SURTI","Western Ghats Hill","Nagori","Eastern Ghats Hill","Bachaur","Satpura Hill","Nimari","Vindhya Hill","PANDHARPURI","Maikal Hill","Ponwar","Nilgiri Hill","Bargur","Palani Hill","Punganur","Shevaroy Hill","BHADAWARI","Anamalai Hill","Rathi","Cardamom Hill","Dangi","Agasthyamalai Hill","Red Kandhari","Pachamalai Hill","Gaolao","Jawadhu Hill","Siri","Kalrayan Hill","Deoni","Sirumalai Hill","Tharparkar","Sankagiri Hill","MEHSANA","Kolli Hill","Umblachery","Pudukkottai Hill","Dhanni","Sivaganga Hill","Vechur","Dindigul Hill","Ghumusari","Theni Hill","Yak","Virudhunagar Hill","Gangatiri","Tenkasi Hill",
      ];
    }
  }

  /// Get all common diseases
  Future<List<CommonDisease>> getCommonDiseases() async {
    try {
      print('🔍 Fetching all common diseases...');
      
      final response = await supabase
          .from('common_diseases')
          .select('id, diseases') // Use 'diseases' column as per PostgrestException hint
          .order('id')
          .limit(5); // Limit to 5 for debugging
      
      print('🔍 Raw response from common_diseases table: $response');
      print('🔍 Response type: ${response.runtimeType}');
      print('🔍 Response length: ${response.length}');
      
      if (response.isNotEmpty) {
        print('🔍 First item columns: ${response.first.keys.toList()}');
        print('🔍 First item values: ${response.first.values.toList()}');
      }
      
      return (response as List).map((item) {
        print('🔍 Processing common disease item: $item');
        return CommonDisease.fromJson(item);
      }).toList();
    } catch (e) {
      print('❌ Error fetching common diseases: $e');
      return [];
    }
  }

  /// Get health features for a specific breed
  Future<List<HealthFeature>> getBreedFeatures(String breed) async {
    try {
      // First get breed ID from cow_buffalo table
      final breedResponse = await supabase
          .from('cow_buffalo')
          .select('id')
          .eq('breed', breed)
          .limit(1);
      
      if (breedResponse.isEmpty) {
        return [];
      }
      
      final breedId = breedResponse.first['id'];
      
      // Get features for this breed (assuming Features table has breed_id reference)
      final featuresResponse = await supabase
          .from('Features')
          .select('*')
          .eq('breed_id', breedId);  // Assuming there's a breed_id column
      
      return (featuresResponse as List).map((item) {
        return HealthFeature.fromJson(item);
      }).toList();
    } catch (e) {
      print('Error fetching breed features: $e');
      return [];
    }
  }

  /// Get diseases associated with a specific breed
  Future<List<CommonDisease>> getDiseasesForBreed(String breed) async {
    try {
      print('🔍 Fetching diseases for breed: $breed');
      
      // Step 1: Get breed ID from cow_buffalo table using breed name
      final breedResponse = await supabase
          .from('cow_buffalo')
          .select('id')
          .eq('breed', breed)
          .limit(1);
      
      print('🔍 Breed lookup response: $breedResponse');
      
      if (breedResponse.isEmpty) {
        print('❌ Breed not found: $breed');
        print('🔍 Trying to get all diseases as fallback...');
        return await getCommonDiseases(); // Fallback to show all diseases
      }
      
      final breedId = breedResponse.first['id'];
      print('✅ Found breed ID $breedId for breed: $breed');
      
      // Step 2: Get diseases from common_diseases table where id matches breed ID
      final diseasesResponse = await supabase
          .from('common_diseases')
          .select('id, diseases') // Use 'diseases' column as per PostgrestException hint
          .eq('id', breedId);
      
      print('🔍 Diseases query response: $diseasesResponse');
      print('📊 Found ${diseasesResponse.length} diseases for breed ID: $breedId');
      
      if (diseasesResponse.isEmpty) {
        print('❌ No diseases found for breed ID: $breedId');
        print('🔍 Trying alternative approach - get all diseases with matching breed pattern...');
        
        // Alternative approach: Get all diseases and filter by breed name pattern
        final allDiseases = await getCommonDiseases();
        print('📊 Total diseases in database: ${allDiseases.length}');
        
        // For debugging, let's return some diseases if available
        if (allDiseases.isNotEmpty) {
          final sampleDiseases = allDiseases.take(3).toList(); // Return first 3 as sample
          print('🔄 Returning ${sampleDiseases.length} sample diseases for debugging');
          return sampleDiseases;
        }
        
        return [];
      }
      
      // Convert response to CommonDisease objects
      final diseases = (diseasesResponse as List).map((item) {
        print('🔍 Raw disease item from database: $item');
        print('🔍 Disease field value: "${item['disease']}"');
        print('🔍 Disease field type: ${item['disease'].runtimeType}');
        
        final disease = CommonDisease.fromJson(item);
        print('🔍 Parsed disease object - ID: ${disease.id}, Disease: "${disease.disease}"');
        
        return disease;
      }).toList();
      
      print('✅ Successfully returning ${diseases.length} diseases for breed: $breed');
      
      // Additional debugging - print each disease name
      for (int i = 0; i < diseases.length; i++) {
        print('🔍 Disease $i: ID=${diseases[i].id}, Name="${diseases[i].disease}"');
      }
      
      return diseases;
      
    } catch (e) {
      print('❌ Error fetching diseases for breed: $e');
      print('🔄 Attempting fallback to all diseases...');
      
      try {
        final fallbackDiseases = await getCommonDiseases();
        print('🔄 Fallback returned ${fallbackDiseases.length} diseases');
        return fallbackDiseases.take(5).toList(); // Return first 5 as fallback
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        return [];
      }
    }
  }

  /// Perform health check analysis
  Future<HealthCheckResult?> performHealthCheck(HealthCheckRequest request) async {
    try {
      print('Performing health check for breed: ${request.breed}, gender: ${request.gender}');
      
      // Get breed features
      final breedFeatures = await getBreedFeatures(request.breed);
      
      // Get diseases specifically for this breed
      final breedDiseases = await getDiseasesForBreed(request.breed);
      
      print('Found ${breedDiseases.length} diseases for breed ${request.breed}');
      
      // Calculate a match percentage based on breed and features
      double matchPercentage = 75.0; // Base percentage
      
      // Adjust based on breed (some breeds are healthier)
      if (request.breed.toLowerCase().contains('gir') || 
          request.breed.toLowerCase().contains('hariana')) {
        matchPercentage += 10.0; // Hardy breeds
      }
      
      // Adjust based on gender
      if (request.gender == 'f') {
        matchPercentage += 5.0; // Females might have different health profiles
      }
      
      // Adjust based on selected features
      matchPercentage += (request.selectedFeatures.length * 2.5);
      
      // Clamp to reasonable range
      matchPercentage = matchPercentage.clamp(60.0, 95.0);
      
      return HealthCheckResult(
        breed: request.breed,
        gender: request.gender,
        potentialDiseases: breedDiseases,
        breedFeatures: breedFeatures,
        matchPercentage: matchPercentage,
      );
    } catch (e) {
      print('Error performing health check: $e');
      return null;
    }
  }
}