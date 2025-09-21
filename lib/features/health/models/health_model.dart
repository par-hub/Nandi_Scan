class CommonDisease {
  final int id;
  final String disease;

  CommonDisease({
    required this.id,
    required this.disease,
  });

  factory CommonDisease.fromJson(Map<String, dynamic> json) {
    print('🔍 CommonDisease.fromJson called with: $json');
    
    final id = json['id'] ?? 0;
    // Database uses 'diseases' column (plural) as confirmed by PostgrestException
    final disease = json['diseases'] ?? json['disea'] ?? json['disease'] ?? 'Unknown Disease';
    
    print('🔍 Parsed - ID: $id, Disease: "$disease" (from diseases column)');
    
    return CommonDisease(
      id: id,
      disease: disease.toString().trim(), // Ensure it's a string and trim whitespace
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diseases': disease, // Using 'diseases' as per actual database schema
    };
  }
}

class HealthFeature {
  final int specificationId;
  final double? height;
  final String? muscleType;
  final bool? hump;
  final String? color;
  final String? pattern;
  final String? hornShape;
  final String? earShape;
  final String? foreheadShape;
  final double? gestationPeriod;
  final double? fertilityAge;
  final int? weight;
  final int? udder;
  final String? purpose;
  final int? teat;
  final double? milkYield;
  final String? distinctiveFeature;

  HealthFeature({
    required this.specificationId,
    this.height,
    this.muscleType,
    this.hump,
    this.color,
    this.pattern,
    this.hornShape,
    this.earShape,
    this.foreheadShape,
    this.gestationPeriod,
    this.fertilityAge,
    this.weight,
    this.udder,
    this.purpose,
    this.teat,
    this.milkYield,
    this.distinctiveFeature,
  });

  factory HealthFeature.fromJson(Map<String, dynamic> json) {
    return HealthFeature(
      specificationId: json['specification_id'] ?? 0,
      height: json['height']?.toDouble(),
      muscleType: json['muscle_type'],
      hump: json['hump'],
      color: json['color'],
      pattern: json['pattern'],
      hornShape: json['horn_shape'],
      earShape: json['ear_shape'],
      foreheadShape: json['forehead_shape'],
      gestationPeriod: json['gestation_period']?.toDouble(),
      fertilityAge: json['fertility_age']?.toDouble(),
      weight: json['weight'],
      udder: json['udder'],
      purpose: json['purpose'],
      teat: json['teat'],
      milkYield: json['milk_yield']?.toDouble(),
      distinctiveFeature: json['distinctive_feature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specification_id': specificationId,
      'height': height,
      'muscle_type': muscleType,
      'hump': hump,
      'color': color,
      'pattern': pattern,
      'horn_shape': hornShape,
      'ear_shape': earShape,
      'forehead_shape': foreheadShape,
      'gestation_period': gestationPeriod,
      'fertility_age': fertilityAge,
      'weight': weight,
      'udder': udder,
      'purpose': purpose,
      'teat': teat,
      'milk_yield': milkYield,
      'distinctive_feature': distinctiveFeature,
    };
  }
}

class HealthCheckRequest {
  final String breed;
  final String gender;
  final List<String> selectedFeatures;

  HealthCheckRequest({
    required this.breed,
    required this.gender,
    required this.selectedFeatures,
  });

  Map<String, dynamic> toJson() {
    return {
      'breed': breed,
      'gender': gender,
      'selected_features': selectedFeatures,
    };
  }
}

class HealthCheckResult {
  final String breed;
  final String gender;
  final List<CommonDisease> potentialDiseases;
  final List<HealthFeature> breedFeatures;
  final double matchPercentage;

  HealthCheckResult({
    required this.breed,
    required this.gender,
    required this.potentialDiseases,
    required this.breedFeatures,
    required this.matchPercentage,
  });
}