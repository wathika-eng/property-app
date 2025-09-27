class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final DateTime createdAt;
  final bool isLandlord;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    required this.createdAt,
    this.isLandlord = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(json['created_at']),
      isLandlord: json['is_landlord'] == 1 || json['is_landlord'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
      'is_landlord': isLandlord ? 1 : 0,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImage,
    DateTime? createdAt,
    bool? isLandlord,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      isLandlord: isLandlord ?? this.isLandlord,
    );
  }
}