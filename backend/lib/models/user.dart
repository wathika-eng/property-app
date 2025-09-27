class User {
  final String id;
  final String email;
  final String passwordHash;
  final String name;
  final String? profileImage;
  final bool isLandlord;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.profileImage,
    this.isLandlord = false,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      passwordHash: map['password_hash'],
      name: map['name'],
      profileImage: map['profile_image'],
      isLandlord: map['is_landlord'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'profile_image': profileImage,
      'is_landlord': isLandlord ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image': profileImage,
      'is_landlord': isLandlord,
      'created_at': createdAt.toIso8601String(),
    };
  }
}