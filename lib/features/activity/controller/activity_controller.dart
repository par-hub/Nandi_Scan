import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_model.dart';
import '../repository/activity_repository.dart';
import '../../../common/auth_session_service.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

final activityControllerProvider = Provider<ActivityController>((ref) {
  final repository = ref.read(activityRepositoryProvider);
  return ActivityController(repository);
});

final recentActivitiesProvider = FutureProvider.family<List<ActivityModel>, String>((ref, userId) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getRecentActivitiesByUserId(userId, limit: 10);
});

final homeRecentActivitiesProvider = FutureProvider.family<List<ActivityModel>, String>((ref, userId) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getRecentActivitiesByUserId(userId, limit: 3);
});

final cowActivitiesProvider = FutureProvider.family<List<ActivityModel>, String>((ref, cowId) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getActivitiesByCowId(cowId);
});

class ActivityController {
  final ActivityRepository _repository;

  ActivityController(this._repository);

  Future<List<ActivityModel>> getUserActivities({int limit = 10}) async {
    try {
      final userId = await AuthSessionService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final activities = await _repository.getRecentActivitiesByUserId(userId, limit: limit);
      return activities;
    } catch (e) {
      print('Error loading user activities: $e');
      rethrow;
    }
  }

  Future<bool> createActivity({
    required String cowId,
    required String activity,
  }) async {
    try {
      final userId = await AuthSessionService.getCurrentUserId();
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _repository.createActivity(
        cowId: cowId,
        activity: activity,
        userId: userId,
      );
      
      return true;
    } catch (e) {
      print('Error creating activity: $e');
      return false;
    }
  }
}
