class CattleRegistrationModel {
  final String breed;
  final String gender;
  final double height;
  final String color;
  final double weight;
  final String? userId;  // Changed from int? to String? for UUID
  final int? breedId;

  CattleRegistrationModel({
    required this.breed,
    required this.gender,
    required this.height,
    required this.color,
    required this.weight,
    this.userId,
    this.breedId,
  });

  Map<String, dynamic> toJson() {
    return {
      'breed': breed,
      'gender': gender,
      'height': height.round(), // Convert to integer for database
      'color': color,
      'weight': weight.round(), // Convert to integer for database
      'user-id': userId,
      'breed_id': breedId,
    };
  }

  factory CattleRegistrationModel.fromJson(Map<String, dynamic> json) {
    return CattleRegistrationModel(
      breed: json['breed'] ?? '',
      gender: json['gender'] ?? '',
      height: (json['height'] ?? 0.0).toDouble(),
      color: json['color'] ?? '',
      weight: (json['weight'] ?? 0.0).toDouble(),
      userId: json['user-id'],  // UUID is a string, no conversion needed
      breedId: json['breed_id'],
    );
  }
}

class BreedInfo {
  final int id;
  final String breed;
  final String gender;
  final int count;

  BreedInfo({
    required this.id,
    required this.breed,
    required this.gender,
    required this.count,
  });

  factory BreedInfo.fromJson(Map<String, dynamic> json) {
    return BreedInfo(
      id: json['id'] ?? 0,
      breed: json['breed'] ?? '',
      gender: json['gender'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}