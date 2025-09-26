class UserProfile {
  final String id;
  final String? name;
  final double? phone;
  final String email;
  final int cattlesOwned;

  const UserProfile({
    required this.id,
    this.name,
    this.phone,
    required this.email,
    this.cattlesOwned = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['user-id'] as String,
      name: json['name'] as String?,
      phone: (json['phone'] as num?)?.toDouble(),
      email: json['email'] ?? '',
      cattlesOwned: (json['cattles_owned'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user-id': id,
      'name': name,
      'phone': phone,
      'cattles_owned': cattlesOwned,
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    double? phone,
    String? email,
    int? cattlesOwned,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      cattlesOwned: cattlesOwned ?? this.cattlesOwned,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.email == email &&
        other.cattlesOwned == cattlesOwned;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, phone, email, cattlesOwned);
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, phone: $phone, email: $email, cattlesOwned: $cattlesOwned)';
  }
}