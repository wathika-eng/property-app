class Review {
  final String id;
  final String listingId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userProfileImage: json['user_profile_image'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'user_id': userId,
      'user_name': userName,
      'user_profile_image': userProfileImage,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromRow(Map<String, dynamic> row) {
    return Review(
      id: row['id'] as String,
      listingId: row['listing_id'] as String,
      userId: row['user_id'] as String,
      userName: row['user_name'] as String,
      userProfileImage: row['user_profile_image'] as String?,
      rating: (row['rating'] as num).toDouble(),
      comment: row['comment'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}