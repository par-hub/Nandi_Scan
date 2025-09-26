class ActivityModel {
  final int id;
  final String cowId;
  final String? activity;
  final String userId;
  final DateTime dateTime;

  ActivityModel({
    required this.id,
    required this.cowId,
    this.activity,
    required this.userId,
    required this.dateTime,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as int,
      cowId: json['cow_id'].toString(), // Handle both int and String
      activity: json['activity'] as String?,
      userId: json['user_id'] as String,
      dateTime: json['date_time'] != null 
          ? DateTime.parse(json['date_time'] as String)
          : DateTime.now(), // Fallback to current time if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cow_id': cowId,
      'activity': activity,
      'user_id': userId,
      'date_time': dateTime.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    // Try to convert cowId to int if it's a valid number
    dynamic cowIdValue = cowId;
    if (int.tryParse(cowId) != null) {
      cowIdValue = int.parse(cowId);
    }
    
    return {
      'cow_id': cowIdValue,
      'activity': activity,
      'user_id': userId,
    };
  }
}