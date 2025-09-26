import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ActivityModel>> getRecentActivitiesByUserId(String userId, {int limit = 10}) async {
    try {
      print('Fetching activities for user: $userId');
      
      final response = await _client
          .from('activity')
          .select('*')
          .eq('user_id', userId)
          .order('date_time', ascending: false)
          .limit(limit);

      print('Activity response: $response');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ActivityModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching activities: $e');
      throw Exception('Failed to fetch activities: $e');
    }
  }

  Future<ActivityModel> createActivity({
    required String cowId,
    required String activity,
    required String userId,
  }) async {
    try {
      print('Creating activity for cow: $cowId, user: $userId');
      
      // Try to convert cowId to int if it's a valid number
      dynamic cowIdValue = cowId;
      if (int.tryParse(cowId) != null) {
        cowIdValue = int.parse(cowId);
      }
      
      final activityData = {
        'cow_id': cowIdValue,
        'activity': activity,
        'user_id': userId,
      };
      
      final response = await _client
          .from('activity')
          .insert(activityData)
          .select()
          .single();

      print('Activity creation response: $response');
      return ActivityModel.fromJson(response);
    } catch (e) {
      print('Error creating activity: $e');
      throw Exception('Failed to create activity: $e');
    }
  }

  Future<List<ActivityModel>> getActivitiesByCowId(String cowId) async {
    try {
      print('Fetching activities for cow: $cowId');
      
      final response = await _client
          .from('activity')
          .select('*')
          .eq('cow_id', cowId)
          .order('date_time', ascending: false);

      print('Cow activities response: $response');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ActivityModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching cow activities: $e');
      throw Exception('Failed to fetch cow activities: $e');
    }
  }
}