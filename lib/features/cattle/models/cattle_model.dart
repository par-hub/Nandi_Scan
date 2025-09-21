class CattleModel {
  final int specifiedId;
  final double height;
  final String color;
  final double weight;
  final String userId;
  final int? breedId;
  final String gender;
  final String? breedName; // From cow_buffalo table join

  CattleModel({
    required this.specifiedId,
    required this.height,
    required this.color,
    required this.weight,
    required this.userId,
    required this.gender,
    this.breedId,
    this.breedName,
  });

  factory CattleModel.fromJson(Map<String, dynamic> json) {
    return CattleModel(
      specifiedId: json['specified_id'] ?? 0,
      height: (json['height'] ?? 0.0).toDouble(),
      color: json['color'] ?? '',
      weight: (json['weight'] ?? 0.0).toDouble(),
      userId: json['user-id'] ?? '',
      gender: json['gender'] ?? '',
      breedId: json['breed_id'],
      breedName: json['cow_buffalo']?['breed'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specified_id': specifiedId,
      'height': height,
      'color': color,
      'weight': weight,
      'user-id': userId,
      'gender': gender,
      'breed_id': breedId,
    };
  }

  // Convert height from meters to feet for display
  String get heightInFeet {
    // Assuming height is stored in meters, convert to feet
    final heightInFeet = height * 3.28084;
    return '${heightInFeet.toStringAsFixed(1)} ft';
  }

  // Format weight for display
  String get weightFormatted {
    return '${weight.toStringAsFixed(0)} kg';
  }

  // Get gender display with proper capitalization
  String get genderDisplay {
    return gender.toLowerCase() == 'm' ? 'Male' : 'Female';
  }

  // Get a display name (could be enhanced later with actual names)
  String get displayName {
    return '${breedName ?? 'Unknown'} #$specifiedId';
  }
}