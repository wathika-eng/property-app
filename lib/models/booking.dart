class Booking {
  final String id;
  final String userId;
  final String userName;
  final String listingId;
  final String listingTitle;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String status; // pending, confirmed, cancelled
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.listingId,
    required this.listingTitle,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      listingId: json['listing_id'],
      listingTitle: json['listing_title'],
      checkIn: DateTime.parse(json['check_in']),
      checkOut: DateTime.parse(json['check_out']),
      guests: json['guests'],
      totalPrice: json['total_price'].toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'listing_id': listingId,
      'listing_title': listingTitle,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut.toIso8601String(),
      'guests': guests,
      'total_price': totalPrice,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get numberOfNights {
    return checkOut.difference(checkIn).inDays;
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? listingId,
    String? listingTitle,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}