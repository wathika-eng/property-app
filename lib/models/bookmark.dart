class Bookmark {
  final String id;
  final String userId;
  final String listingId;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      userId: json['user_id'],
      listingId: json['listing_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'listing_id': listingId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}