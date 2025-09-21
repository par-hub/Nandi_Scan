class CattleRegistrationModel {
  final String breed;
  final String gender;
  final double height;
  final String color;
  final double weight;
  final int? userId;  // Changed from String? to int?
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
      'height': height,
      'color': color,
      'weight': weight,
      'user_id': userId,
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
      userId: json['user_id'] != null ? (json['user_id'] as num).toInt() : null,  // Handle int conversion
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